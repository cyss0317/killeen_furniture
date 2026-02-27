module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:show, :edit, :update, :destroy, :update_stock, :toggle_featured, :publish, :archive, :update_price, :move]

    SORTABLE_COLUMNS = %w[name selling_price stock_quantity created_at status].freeze

    def index
      scope = Product.includes(:category, :images_attachments)

      scope = scope.search_by(params[:q]) if params[:q].present?
      # When a keyword search is active, ignore status filter so SKU/name searches
      # always find the product regardless of draft/published state.
      scope = scope.where(status: params[:status]) if params[:status].present? && params[:q].blank?
      scope = scope.by_category(params[:category_id]) if params[:category_id].present?
      scope = scope.by_color(params[:color]) if params[:color].present?

      @sort      = SORTABLE_COLUMNS.include?(params[:sort]) ? params[:sort] : "created_at"
      @direction = params[:direction] == "asc" ? "asc" : "desc"
      scope      = scope.reorder("#{@sort} #{@direction}")

      @pagy, @products = pagy(:offset, scope, limit: 25)

      # When color is filtered, restrict categories + statuses to those with that color
      if params[:color].present?
        color_product_base = Product.where(color: params[:color])
        @categories        = Category.where(id: color_product_base.select(:category_id)).order(:name)
        @available_statuses = color_product_base.distinct.pluck(:status)
      else
        @categories         = Category.ordered
        @available_statuses = nil
      end

      @colors = Product.where.not(color: [nil, ""]).distinct.pluck(:color).sort
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

    def update_price
      new_price = params[:selling_price]
      if @product.update_selling_price(new_price)
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_product_path(@product), notice: "Price updated." }
        end
      else
        redirect_to admin_product_path(@product), alert: "Failed to update price."
      end
    end

    def move
      category = Category.find(params[:category_id])
      @product.update!(category: category)
      render json: { ok: true }
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Category not found" }, status: :not_found
    rescue => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def toggle_featured
      @product.update!(featured: !@product.featured?)
      state = @product.featured? ? "featured" : "unfeatured"
      redirect_back(fallback_location: admin_products_path, notice: "Product #{state}.")
    end

    def import_screenshot
      unless params[:screenshot].present?
        render json: { error: "No screenshot uploaded" }, status: :unprocessable_entity and return
      end

      result = ProductImport::FromScreenshot.call(screenshot_file: params[:screenshot])

      if result.error
        render json: { error: result.error }, status: :unprocessable_entity
      else
        render json: { data: result.data }
      end
    end

    def scrape_vendor
      sku   = params[:sku].to_s.strip
      brand = params[:brand].to_s.strip

      if sku.blank? || brand.blank?
        render json: { error: "SKU and brand are required" }, status: :unprocessable_entity and return
      end

      result = ProductImport::VendorScraper.call(sku: sku, brand: brand, page_url: params[:page_url].presence)

      if result.error && result.image_urls.blank?
        render json: { error: result.error }, status: :unprocessable_entity
      else
        render json: {
          image_urls: result.image_urls || [],
          data: result.data || {},
          warning: result.error
        }
      end
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
        :weight, :material, :color, :page_url,
        dimensions: [:width, :height, :depth],
        images: [],
        vendor_image_urls: []
      )
    end
  end
end
