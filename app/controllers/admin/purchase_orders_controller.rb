class Admin::PurchaseOrdersController < Admin::BaseController
  include Pagy::Method

  SORTABLE_COLUMNS = %w[reference_number ordered_at created_at status].freeze

  before_action :set_purchase_order, only: [:show, :receive]

  def index
    authorize PurchaseOrder, :index?

    @period = params[:period].presence_in(%w[week month year]) || "month"
    @offset = params[:offset].to_i

    now    = Time.current
    anchor = case @period
             when "week"  then now + @offset.weeks
             when "year"  then now + @offset.years
             else              now + @offset.months
             end

    @period_range = case @period
                    when "week"  then anchor.beginning_of_week.to_date..anchor.end_of_week.to_date
                    when "year"  then anchor.beginning_of_year.to_date..anchor.end_of_year.to_date
                    else              anchor.beginning_of_month.to_date..anchor.end_of_month.to_date
                    end

    @period_display = case @period
                      when "week"  then "Week of #{anchor.beginning_of_week.strftime('%b %-d')} – #{anchor.end_of_week.strftime('%b %-d, %Y')}"
                      when "year"  then anchor.strftime("%Y")
                      else              anchor.strftime("%B %Y")
                      end

    @q = params[:q].to_s.strip

    scope = policy_scope(PurchaseOrder)
              .includes(:created_by, purchase_order_items: :product)

    # Period filter is bypassed when a search query is active
    if @q.present?
      q = "%#{@q}%"
      scope = scope.where(
        "purchase_orders.reference_number ILIKE :q OR purchase_orders.brand ILIKE :q " \
        "OR purchase_orders.notes ILIKE :q " \
        "OR purchase_orders.id IN (SELECT purchase_order_id FROM purchase_order_items WHERE product_sku ILIKE :q OR product_name ILIKE :q)",
        q: q
      )
    else
      scope = scope.where(ordered_at: @period_range)
    end

    scope = scope.recent

    if params[:status].present? && PurchaseOrder.statuses.key?(params[:status])
      scope = scope.where(status: params[:status])
    end

    @sort      = params[:sort].in?(SORTABLE_COLUMNS) ? params[:sort] : "ordered_at"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    scope      = scope.reorder("purchase_orders.#{@sort} #{@direction}")

    @pagy, @purchase_orders = pagy(:offset, scope, limit: 25)

    # Build status counts from a clean scope (no ORDER BY) to avoid PG grouping errors
    if @q.present?
      q = "%#{@q}%"
      @status_counts = PurchaseOrder.where(
                                      "reference_number ILIKE :q OR brand ILIKE :q OR notes ILIKE :q " \
                                      "OR id IN (SELECT purchase_order_id FROM purchase_order_items WHERE product_sku ILIKE :q OR product_name ILIKE :q)",
                                      q: q
                                    )
                                    .group(:status)
                                    .count
    else
      @status_counts = PurchaseOrder.where(ordered_at: @period_range).group(:status).count
    end
  end

  def show
    authorize @po
    @items = @po.purchase_order_items.includes(:product).order(:product_name)
  end

  def new
    authorize PurchaseOrder, :new?
    @po       = PurchaseOrder.new(status: :submitted, ordered_at: Date.current)
    @products = Product.where.not(status: :archived).order(:name)
  end

  def create
    authorize PurchaseOrder, :create?

    line_items = (params[:purchase_order][:line_items] || [])
                   .select { |i| i[:product_id].present? && i[:quantity_ordered].to_i > 0 }

    if line_items.empty?
      @po       = PurchaseOrder.new(po_params)
      @products = Product.where.not(status: :archived).order(:name)
      flash.now[:alert] = "Add at least one product."
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      # Use the brand of the first product as the brand for the PO
      first_product = Product.find(line_items.first[:product_id])
      @po = PurchaseOrder.create!(po_params.merge(created_by: current_user, brand: first_product.brand))

      line_items.each do |item|
        product = Product.find(item[:product_id])
        @po.purchase_order_items.create!(
          product:          product,
          quantity_ordered: item[:quantity_ordered].to_i,
          unit_cost:        item[:unit_cost].to_d,
          product_name:     product.name,
          product_sku:      product.sku
        )
      end
    end

    redirect_to admin_purchase_order_path(@po), notice: "Purchase order #{@po.reference_number} created."
  rescue ActiveRecord::RecordInvalid => e
    @po       = PurchaseOrder.new(po_params)
    @products = Product.where.not(status: :archived).order(:name)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def receive
    authorize @po, :receive?

    receive_params = (params[:items] || {}).to_unsafe_h.transform_keys(&:to_s)
    result = PurchaseOrders::ReceiveItems.call(
      purchase_order: @po,
      receive_params: receive_params
    )

    if result.success?
      redirect_to admin_purchase_order_path(@po), notice: "Receipt recorded. Stock and costs updated."
    else
      redirect_to admin_purchase_order_path(@po), alert: "Could not record receipt: #{result.error}"
    end
  end

  def import_screenshot
    authorize PurchaseOrder, :import_screenshot?
    return if request.get?

    files = Array(params[:files]).compact.select(&:present?)
    files = [ params[:file] ].compact if files.empty? && params[:file].present?

    if files.empty?
      flash.now[:alert] = "Please select at least one image file."
      return render :import_screenshot, status: :unprocessable_entity
    end

    common_params = {
      reference_number: params[:reference_number].presence,
      ordered_at:       params[:ordered_at].presence,
      notes:            params[:notes].presence,
      created_by:       current_user
    }

    result = if files.size == 1
      PurchaseOrders::ImportScreenshot.call(file: files.first, **common_params)
    else
      PurchaseOrders::ImportMultipleScreenshots.call(files: files, **common_params)
    end

    if result.success?
      parts = []
      parts << "#{result.created_products.size} new #{"product".pluralize(result.created_products.size)} created as draft" if result.created_products.any?
      parts << "#{result.updated_products.size} #{"product".pluralize(result.updated_products.size)} updated"               if result.updated_products.any?
      parts << "#{result.skipped_rows.size} #{"row".pluralize(result.skipped_rows.size)} skipped"                           if result.skipped_rows.any?

      all_pos = (result.purchase_orders.presence || [ result.purchase_order ]).compact

      if all_pos.empty?
        # All invoices were already imported (all duplicates)
        notice = "All invoices already imported — #{result.skipped_rows.size} #{"duplicate".pluralize(result.skipped_rows.size)} skipped."
        redirect_to admin_purchase_orders_path, notice: notice
      elsif all_pos.size == 1
        po        = all_pos.first
        file_note = files.size > 1 ? " (from #{files.size} screenshots)" : ""
        notice    = "PO #{po.reference_number} from #{result.supplier_name} imported#{file_note} — #{po.purchase_order_items.size} items. #{parts.join(', ')}."
        redirect_to admin_purchase_order_path(po), notice: notice
      else
        po_numbers = all_pos.map(&:reference_number).join(", ")
        notice = "#{all_pos.size} purchase orders created from #{result.supplier_name}: #{po_numbers}. #{parts.join(', ')}."
        redirect_to admin_purchase_orders_path, notice: notice
      end
    else
      Rails.logger.error "[ImportScreenshot] Failed — #{result.error}"
      flash.now[:alert] = result.error
      render :import_screenshot, status: :unprocessable_entity
    end
  end

  private

  def set_purchase_order
    @po = PurchaseOrder.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_purchase_orders_path, alert: "Purchase order not found."
  end

  def po_params
    params.require(:purchase_order).permit(:reference_number, :status, :ordered_at, :notes)
  end
end
