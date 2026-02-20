module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy, :update_stock, :toggle_featured, :publish, :archive]

    def index
      scope = Product.includes(:category, :images_attachments)

      scope = scope.search_by(params[:q]) if params[:q].present?
      scope = scope.where(status: params[:status]) if params[:status].present?
      scope = scope.by_category(params[:category_id]) if params[:category_id].present?

      @pagy, @products = pagy(:offset, scope.order(created_at: :desc), limit: 25)
      @categories = Category.ordered
    end

    def show
    end

    def new
      @product    = Product.new(markup_percentage: GlobalSetting.global_markup)
      @categories = Category.ordered
    end

    def create
      @product = Product.new(product_params)
      if @product.save
        redirect_to admin_product_path(@product), notice: "Product created successfully."
      else
        @categories = Category.ordered
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @categories = Category.ordered
    end

    def update
      if @product.update(product_params)
        redirect_to admin_product_path(@product), notice: "Product updated."
      else
        @categories = Category.ordered
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @product.update!(status: :archived)
      redirect_to admin_products_path, notice: "\"#{@product.name}\" has been archived."
    end

    def publish
      @product.update!(status: :published)
      redirect_back(fallback_location: admin_products_path, notice: "Product published.")
    end

    def archive
      @product.update!(status: :archived)
      redirect_back(fallback_location: admin_products_path, notice: "Product archived.")
    end

    def update_stock
      quantity_change = params[:quantity_change].to_i
      reason          = params[:reason]

      if quantity_change == 0
        redirect_back(fallback_location: admin_product_path(@product), alert: "Quantity change cannot be zero.")
        return
      end

      adjustment = @product.stock_adjustments.build(
        quantity_change: quantity_change,
        reason:          reason,
        admin_user:      current_user
      )

      if adjustment.save
        respond_to do |format|
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              "stock-display-#{@product.id}",
              partial: "admin/products/stock_display",
              locals:  { product: @product.reload }
            )
          end
          format.html { redirect_back(fallback_location: admin_product_path(@product), notice: "Stock updated.") }
        end
      else
        redirect_back(fallback_location: admin_product_path(@product), alert: adjustment.errors.full_messages.to_sentence)
      end
    end

    def toggle_featured
      @product.update!(featured: !@product.featured?)
      state = @product.featured? ? "featured" : "unfeatured"
      redirect_back(fallback_location: admin_products_path, notice: "Product #{state}.")
    end

    private

    def set_product
      @product = Product.friendly.find(params[:id])
    rescue ActiveRecord::RecordNotFound, FriendlyId::SlugNotFoundException
      redirect_to admin_products_path, alert: "Product not found."
    end

    def product_params
      params.require(:product).permit(
        :name, :brand, :sku, :category_id,
        :short_description, :description,
        :base_cost, :markup_percentage,
        :stock_quantity, :status, :featured,
        :weight, :material, :color,
        dimensions: [:width, :height, :depth],
        images: []
      )
    end
  end
end
