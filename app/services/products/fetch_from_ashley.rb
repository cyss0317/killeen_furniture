require "net/http"
require "openssl"

module Products
  # Best-effort enrichment of a product record using data scraped from
  # ashleyfurniture.com.  Failures are silently swallowed so callers never
  # need to rescue — this is always optional enhancement, never blocking.
  class FetchFromAshley
    BASE_URL   = "https://www.ashleyfurniture.com"
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    TIMEOUT    = 10

    # Public convenience — call this from other services.
    # Updates product in-place; returns true on success, false on any failure.
    def self.enrich!(product, series: nil, description: nil)
      new(product: product, series: series, description: description).enrich!
    end

    def initialize(product:, series: nil, description: nil)
      @product     = product
      @series      = series.to_s.strip
      @description = description.to_s.strip
    end

    def enrich!
      # binding.pry
      html = fetch_product_html
      return false unless html

      data = parse_product_data(html)
      return false if data.empty?

      apply_updates(data)
      true
    rescue => e
      Rails.logger.warn "[FetchFromAshley] #{@product.sku}: #{e.class} — #{e.message}"
      false
    end

    private

    # Build the Ashley product page URL from SKU + name info.
    # Ashley URL pattern: /p/{series-description-slug}/{SKU}.html
    def product_url
      slug_source = [@series, @description].select(&:present?).join(" ")
      slug_source = @product.name if slug_source.blank?

      slug = slug_source
               .downcase
               .gsub(/[^a-z0-9\s]/, "")
               .strip
               .gsub(/\s+/, "-")

      "#{BASE_URL}/p/#{slug}/#{@product.sku.downcase}.html"
    end

    def fetch_product_html
      # We no longer fetch HTML directly here. We delegate to VendorScraper.
      result = ProductImport::VendorScraper.call(sku: @product.sku, brand: "ashley", page_url: product_url)

      # If direct URL fallback or scrape failed, try search fallback
      if result.image_urls.blank?
        result = ProductImport::VendorScraper.call(sku: @product.sku, brand: "ashley")
      end

      if result.image_urls.any?
        data = (result.data || {}).merge(image_urls: result.image_urls)
        return data
      end

      nil
    end

    # parse_product_data is now mostly handled by the scraper, but we keep the structure
    def parse_product_data(scraper_result_data)
      scraper_result_data
    end

    def safe_get(uri, redirects_left = 5)
      return nil if redirects_left.zero?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = (uri.scheme == "https")
      http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      req = Net::HTTP::Get.new(uri.request_uri)
      req["User-Agent"]      = USER_AGENT
      req["Accept"]          = "text/html,application/xhtml+xml"
      req["Accept-Language"] = "en-US,en;q=0.9"

      response = http.request(req)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response["Location"]
        return nil if location.blank?
        redirect_uri = URI.parse(location.start_with?("http") ? location : "#{BASE_URL}#{location}")
        safe_get(redirect_uri, redirects_left - 1)
      else
        nil
      end
    end

    # Extract product data from the HTML — try JSON-LD first, then Open Graph.
    # Map results — the scraper already does the heavy lifting
    def parse_product_data(data)
      data
    end

    def apply_updates(data)
      updates = {}
      updates[:name]   = data[:name]   if data[:name].present? && @product.name != data[:name]
      updates[:weight] = data[:weight] if data[:weight].present? && @product.weight.nil?

      # Map Brand: Prefer "Ashley Furniture" if we successfully scraped the page
      # The @series passed in might just be a collection name (e.g. "Gerridan")
      updates[:brand] = "Ashley Furniture" if @product.brand.blank? || !@product.brand.match?(/ashley/i)

      # Map Dimensions
      # binding.pry
      if data[:dimensions_width].present? || data[:dimensions_height].present? || data[:dimensions_depth].present?
        new_dims = (@product.dimensions || {}).dup
        new_dims["width"]  = data[:dimensions_width]  if data[:dimensions_width].present?
        new_dims["height"] = data[:dimensions_height] if data[:dimensions_height].present?
        new_dims["depth"]  = data[:dimensions_depth]  if data[:dimensions_depth].present?
        updates[:dimensions] = new_dims if new_dims != @product.dimensions
      end

      # Save scraped image URLs if the product doesn't already have any
      if data[:image_urls].present? && @product.vendor_image_urls.blank?
        updates[:vendor_image_urls] = data[:image_urls]
      end


      if data[:description].present? && @product.description.blank?
        updates[:description] = data[:description]
      end

      @product.update!(updates) if updates.any?
    end
  end
end
