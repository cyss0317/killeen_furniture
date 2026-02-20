class ProductsController < ApplicationController
  def index
    scope = Product.published.includes(:category, :images_attachments)

    scope = scope.search_by(params[:q])
    scope = scope.by_category(params[:category_id])
    scope = scope.price_range(params[:min_price], params[:max_price])
    scope = scope.in_stock if params[:in_stock] == "1"

    scope = case params[:sort]
            when "price_asc"  then scope.order(selling_price: :asc)
            when "price_desc" then scope.order(selling_price: :desc)
            when "newest"     then scope.order(created_at: :desc)
            else scope.order(featured: :desc, created_at: :desc)
            end

    @pagy, @products = pagy(:offset, scope)
    @categories = Category.root_categories.includes(:subcategories)
  end

  def show
    @product      = Product.published.friendly.find(params[:slug])
    @related      = Product.published
                           .where(category: @product.category)
                           .where.not(id: @product.id)
                           .includes(:images_attachments)
                           .limit(4)
  rescue ActiveRecord::RecordNotFound, FriendlyId::SlugNotFoundException
    redirect_to products_path, alert: "Product not found."
  end
end
