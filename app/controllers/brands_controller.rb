class BrandsController < ApplicationController
  before_action :no_store

  def show
    @brand = params[:name].to_s.strip
    if @brand.blank?
      redirect_to products_path and return
    end

    scope = Product.published
                   .where("brand ILIKE ?", @brand)
                   .includes(:images_attachments, :category)

    scope = scope.search_by(params[:q])         if params[:q].present?
    scope = scope.in_stock                       if params[:in_stock] == "1"
    scope = scope.by_color(params[:color])
    scope = scope.price_range(params[:min_price], params[:max_price])
    scope = case params[:sort]
            when "price_asc"  then scope.order(selling_price: :asc)
            when "price_desc" then scope.order(selling_price: :desc)
            else scope.order(featured: :desc, created_at: :desc)
            end

    @pagy, @products = pagy(:offset, scope)
    @colors = Product.published
                     .where("brand ILIKE ?", @brand)
                     .where.not(color: [nil, ""])
                     .distinct.pluck(:color).sort
  end
end
