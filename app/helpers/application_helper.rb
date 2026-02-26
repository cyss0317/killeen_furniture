module ApplicationHelper
  def google_maps_url(address_hash)
    parts = [
      address_hash["street_address"],
      address_hash["city"],
      address_hash["state"],
      address_hash["zip_code"]
    ].compact
    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(parts.join(', '))}"
  end

  # Renders the best available image for a product.
  # Prefers vendor_image_urls (direct URL), falls back to ActiveStorage variant.
  # `size` is used only for ActiveStorage variants (e.g. [400, 400]).
  # Returns nil if no image is available.
  def product_image_tag(product, size: [400, 400], **opts)
    if product.vendor_image_urls.present?
      image_tag product.vendor_image_urls.first, **opts
    elsif product.images.attached? && product.primary_image
      image_tag product.primary_image.variant(resize_to_fill: size), **opts
    end
  end
end
