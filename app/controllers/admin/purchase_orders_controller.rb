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

    scope = policy_scope(PurchaseOrder)
              .includes(:created_by, :purchase_order_items)
              .where(ordered_at: @period_range)
              .recent

    if params[:status].present? && PurchaseOrder.statuses.key?(params[:status])
      scope = scope.where(status: params[:status])
    end

    @sort      = params[:sort].in?(SORTABLE_COLUMNS) ? params[:sort] : "ordered_at"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    scope      = scope.reorder("purchase_orders.#{@sort} #{@direction}")

    @pagy, @purchase_orders = pagy(:offset, scope, limit: 25)
    @status_counts = PurchaseOrder.where(ordered_at: @period_range).group(:status).count
  end

  def show
    authorize @po
    @items = @po.purchase_order_items.includes(:product).order(:product_name)
  end

  def new
    authorize PurchaseOrder, :new?
    @po       = PurchaseOrder.new(status: :submitted, ordered_at: Date.current)
    @products = Product.published.order(:name)
  end

  def create
    authorize PurchaseOrder, :create?

    line_items = (params[:purchase_order][:line_items] || [])
                   .select { |i| i[:product_id].present? && i[:quantity_ordered].to_i > 0 }

    if line_items.empty?
      @po       = PurchaseOrder.new(po_params)
      @products = Product.published.order(:name)
      flash.now[:alert] = "Add at least one product."
      return render :new, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      @po = PurchaseOrder.create!(po_params.merge(created_by: current_user))

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
    @products = Product.published.order(:name)
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

  def import_csv
    authorize PurchaseOrder, :import_csv?
    return if request.get?

    unless params[:file].present?
      flash.now[:alert] = "Please select a CSV/TSV file to import."
      return render :import_csv, status: :unprocessable_entity
    end

    unless params[:reference_number].present?
      flash.now[:alert] = "Reference number is required."
      return render :import_csv, status: :unprocessable_entity
    end

    result = PurchaseOrders::ImportCsv.call(
      file:             params[:file],
      reference_number: params[:reference_number],
      ordered_at:       params[:ordered_at].presence,
      notes:            params[:notes].presence,
      created_by:       current_user
    )

    if result.success?
      parts = []
      parts << "#{result.created_products.size} new product(s) created as draft" if result.created_products.any?
      parts << "#{result.updated_products.size} product(s) updated"               if result.updated_products.any?
      parts << "#{result.skipped_rows.size} row(s) skipped"                       if result.skipped_rows.any?

      notice = "PO #{result.purchase_order.reference_number} imported — #{result.purchase_order.purchase_order_items.size} items. #{parts.join(', ')}."
      redirect_to admin_purchase_order_path(result.purchase_order), notice: notice
    else
      flash.now[:alert] = result.error
      render :import_csv, status: :unprocessable_entity
    end
  end

  def import_screenshot
    authorize PurchaseOrder, :import_screenshot?
    return if request.get?

    unless params[:file].present?
      flash.now[:alert] = "Please select an image file."
      return render :import_screenshot, status: :unprocessable_entity
    end

    result = PurchaseOrders::ImportScreenshot.call(
      file:             params[:file],
      reference_number: params[:reference_number].presence,
      ordered_at:       params[:ordered_at].presence,
      notes:            params[:notes].presence,
      created_by:       current_user,
      supplier:         params[:supplier].presence || "ashley"
    )

    if result.success?
      parts = []
      parts << "#{result.created_products.size} new product(s) created as draft" if result.created_products.any?
      parts << "#{result.updated_products.size} product(s) updated"               if result.updated_products.any?
      parts << "#{result.skipped_rows.size} row(s) skipped"                       if result.skipped_rows.any?

      notice = "PO #{result.purchase_order.reference_number} imported — #{result.purchase_order.purchase_order_items.size} items. #{parts.join(', ')}."
      redirect_to admin_purchase_order_path(result.purchase_order), notice: notice
    else
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
