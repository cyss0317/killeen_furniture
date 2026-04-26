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

  def harker_heights_furniture
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)
  end

  def copperas_cove_furniture
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)
  end

  def affordable_furniture
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(12)
    @categories        = Category.root_categories.includes(:subcategories)
  end

  def contact; end

  def financing
    @acima_url = ENV.fetch("ACIMA_FINANCING_URL", nil)
    if @acima_url.present?
      @qr_svg = RQRCode::QRCode.new(@acima_url).as_svg(
        viewbox:        true,
        use_path:       true,
        svg_attributes: { class: "w-full h-full" }
      )
    end
  end
end
