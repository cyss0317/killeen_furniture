class PagesController < ApplicationController
  def home
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)
  end

  def killeen_furniture_store
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)
  end

  def ashley_furniture_killeen
    @ashley_products = Product.published
                              .where("LOWER(brand) LIKE ?", "%ashley%")
                              .includes(:images_attachments, :category)
                              .limit(12)
  end
end
