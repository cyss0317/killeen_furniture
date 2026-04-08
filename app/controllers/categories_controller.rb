class CategoriesController < ApplicationController
  before_action :no_store

  def show
    @category = Category.friendly.find(params[:slug])
    category_ids = [ @category.id ] + @category.subcategories.pluck(:id)

    scope = Product.published
                   .where(category_id: category_ids)
                   .includes(:images_attachments, :category)

    scope = scope.search_by(params[:q]) if params[:q].present?
    scope = scope.in_stock if params[:in_stock] == "1"
    scope = scope.by_color(expand_color_group(params[:color]))
    scope = scope.price_range(params[:min_price], params[:max_price])
    scope = case params[:sort]
            when "price_asc"  then scope.order(selling_price: :asc)
            when "price_desc" then scope.order(selling_price: :desc)
            else                   scope.order(featured: :desc, created_at: :desc)
            end

    @pagy, @products = pagy(:offset, scope)
    @categories = Category.root_categories.includes(:subcategories)

    raw_colors = Product.published
                        .where(category_id: category_ids)
                        .where.not(color: [ nil, "" ])
                        .where("stock_quantity > 0")
                        .distinct.pluck(:color)
    @colors = color_groups_for(raw_colors)
  rescue ActiveRecord::RecordNotFound, FriendlyId::SlugNotFoundException
    redirect_to products_path, alert: "Category not found."
  end
end
