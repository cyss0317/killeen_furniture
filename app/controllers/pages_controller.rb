class PagesController < ApplicationController
  def home
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)
  end
end
