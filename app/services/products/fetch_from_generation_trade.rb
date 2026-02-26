require "net/http"
require "openssl"

module Products
  # Best-effort enrichment of a product record using data scraped from
  # generationtrade.com (Shopify store).  Uses the public Shopify JSON API
  # instead of HTML scraping — much more reliable.
  # Failures are silently swallowed so callers never need to rescue.
  class FetchFromGenerationTrade
    BASE_URL   = "https://generationtrade.com"
    USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36"
    TIMEOUT    = 10

    def self.enrich!(product, series: nil, description: nil)
      new(product: product, series: series, description: description).enrich!
    end

    def initialize(product:, series: nil, description: nil)
      @product     = product
      @series      = series.to_s.strip
      @description = description.to_s.strip
    end

    def enrich!
      product_data = fetch_shopify_product
      return false unless product_data

      data = extract_data(product_data)
      return false if data.empty?

      apply_updates(data)
      true
    rescue => e
      Rails.logger.warn "[FetchFromGenerationTrade] #{@product.sku}: #{e.class} — #{e.message}"
      false
    end

    private

    # Try to find the product via Shopify JSON API.
    # 1) Search by SKU via /search.json
    # 2) Try SKU as a handle via /products/{handle}.json
    def fetch_shopify_product
      # We delegate to VendorScraper which handles Shopify JSON search + handle logic
      result = ProductImport::VendorScraper.call(sku: @product.sku, brand: "generation_trade")

      if result.image_urls.any?
        data = (result.data || {}).merge(image_urls: result.image_urls)
        return data
      end

      nil
    end

    # Fetch /products/{handle}.json and return the product hash, or nil.
    def fetch_product_json(handle)
      body = safe_get_body("#{BASE_URL}/products/#{CGI.escape(handle)}.json")
      return nil unless body

      json    = JSON.parse(body) rescue nil
      product = json&.dig("product")
      return nil unless product

      Rails.logger.info "[FetchFromGenerationTrade] #{@product.sku}: found product '#{product["title"]}' with #{Array(product["images"]).size} images"
      product
    end

    def extract_data(scraper_result_data)
      scraper_result_data
    end

    def apply_updates(data)
      updates = {}
      updates[:name]   = data[:name]   if data[:name].present? && @product.name != data[:name]
      updates[:weight] = data[:weight] if data[:weight].present? && @product.weight.nil?

      # Save scraped image URLs if the product doesn't already have any
      if data[:image_urls].present? && @product.vendor_image_urls.blank?
        updates[:vendor_image_urls] = data[:image_urls]
      end

      @product.update!(updates) if updates.any?

      if data[:description].present? && @product.description.body.blank?
        @product.description = data[:description]
        @product.save!
      end
    end

    def safe_get_body(url, redirects_left = 5)
      return nil if redirects_left.zero?

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = (uri.scheme == "https")
      http.verify_mode  = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      req = Net::HTTP::Get.new(uri.request_uri)
      req["User-Agent"]      = USER_AGENT
      req["Accept"]          = "application/json, text/html, */*"
      req["Accept-Language"] = "en-US,en;q=0.9"

      response = http.request(req)

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPRedirection
        location = response["Location"]
        return nil if location.blank?
        redirect_uri = URI.parse(location.start_with?("http") ? location : "#{BASE_URL}#{location}")
        safe_get_body(redirect_uri.to_s, redirects_left - 1)
      else
        nil
      end
    rescue => e
      Rails.logger.warn "[FetchFromGenerationTrade] fetch #{url}: #{e.message}"
      nil
    end
  end
end
