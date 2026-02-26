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
      # 1) Shopify search JSON endpoint
      body = safe_get_body("#{BASE_URL}/search.json?q=#{CGI.escape(@product.sku)}&type=product")
      if body
        json = JSON.parse(body) rescue nil
        if json
          products = json["results"] || json["products"] || []
          handle   = products.first&.dig("handle") || products.first&.dig("url")&.split("/products/")&.last
          if handle
            product_json = fetch_product_json(handle.to_s.split("?").first)
            return product_json if product_json
          end
        end
      end

      # 2) Try the SKU directly as a product handle (lowercased, hyphenated)
      handle = @product.sku.downcase.gsub(/[^a-z0-9]+/, "-")
      product_json = fetch_product_json(handle)
      return product_json if product_json

      Rails.logger.info "[FetchFromGenerationTrade] #{@product.sku}: no product found via Shopify API"
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

    def extract_data(product_data)
      data = {}

      data[:name] = product_data["title"].presence

      # Extract description from body_html, strip HTML tags
      raw_desc = product_data["body_html"].to_s
      if raw_desc.present?
        data[:description] = ActionController::Base.helpers.strip_tags(raw_desc).squish.presence
      end

      # Extract all image URLs from the Shopify images array
      data[:image_urls] = Array(product_data["images"])
                            .map { |img| img["src"].to_s.gsub(/\?.*\z/, "") }
                            .select { |u| u.match?(/\Ahttps?:\/\//) }
                            .first(8)

      # Weight from variants
      variant = Array(product_data["variants"]).first
      if variant
        weight_val = variant["weight"].to_f
        weight_unit = variant["weight_unit"].to_s.downcase
        # Convert to pounds if needed
        case weight_unit
        when "kg" then data[:weight] = (weight_val * 2.20462).round(2).nonzero?
        when "g"  then data[:weight] = (weight_val * 0.00220462).round(2).nonzero?
        when "oz" then data[:weight] = (weight_val / 16.0).round(2).nonzero?
        else           data[:weight] = weight_val.nonzero?
        end
      end

      data.compact
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
