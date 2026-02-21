class Admin::PurchaseOrdersController < Admin::BaseController
  include Pagy::Method

  SORTABLE_COLUMNS = %w[reference_number ordered_at created_at status].freeze

  before_action :set_purchase_order, only: [:show, :receive]

  def index
    authorize PurchaseOrder, :index?

    scope = policy_scope(PurchaseOrder)
              .includes(:created_by, :purchase_order_items)
              .recent

    if params[:status].present? && PurchaseOrder.statuses.key?(params[:status])
      scope = scope.where(status: params[:status])
    end

    @sort      = params[:sort].in?(SORTABLE_COLUMNS) ? params[:sort] : "created_at"
    @direction = params[:direction] == "asc" ? "asc" : "desc"
    scope      = scope.reorder("purchase_orders.#{@sort} #{@direction}")

    @pagy, @purchase_orders = pagy(:offset, scope, limit: 25)
    @status_counts = PurchaseOrder.group(:status).count
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
