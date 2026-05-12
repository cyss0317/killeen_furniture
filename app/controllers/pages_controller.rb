class PagesController < ApplicationController
  def home
    @featured_products = Product.published.featured.includes(:images_attachments, :category).limit(8)
    @categories        = Category.root_categories.includes(:subcategories)

    # Group published Ashley products by their ashley_payload group_description
    ashley_products = Product.published
                             .where("brand ILIKE ?", "%ashley%")
                             .where("ashley_payload->>'group_description' IS NOT NULL")
                             .includes(:images_attachments)
    @ashley_groups = ashley_products
                       .group_by { |p| p.ashley_payload["group_description"] }
                       .sort_by { |_, prods| -prods.size }
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
