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
      uri  = URI.parse(product_url)
      html = safe_get(uri)

      # If that URL 404s, fall back to the Ashley search page
      if html.nil?
        search_uri = URI.parse("#{BASE_URL}/search/?q=#{URI.encode_www_form_component(@product.sku)}")
        html = safe_get(search_uri)
      end

      html
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
    def parse_product_data(html)
      doc  = Nokogiri::HTML(html)
      data = {}

      # 1) JSON-LD structured data (<script type="application/ld+json">)
      doc.css('script[type="application/ld+json"]').each do |script|
        parsed = JSON.parse(script.text)
        # Handle arrays like [{"@type":"BreadcrumbList",...}, {"@type":"Product",...}]
        entries = parsed.is_a?(Array) ? parsed : [parsed]
        product_entry = entries.find { |e| e["@type"] == "Product" }
        next unless product_entry

        data[:name]        = product_entry["name"].presence
        data[:description] = ActionController::Base.helpers.strip_tags(product_entry["description"].to_s).presence
        data[:image_url]   = Array(product_entry["image"]).first.presence

        # Weight — may be a string like "55 lbs" or a nested object
        weight_raw = product_entry.dig("weight")
        if weight_raw.is_a?(Hash)
          data[:weight] = weight_raw["value"].to_f.nonzero?
        elsif weight_raw.is_a?(String)
          data[:weight] = weight_raw.to_f.nonzero?
        end
        break
      rescue JSON::ParserError
        next
      end

      # 2) Fall back to Open Graph meta tags
      data[:name]      ||= doc.at_css('meta[property="og:title"]')&.attr("content").presence
      data[:image_url] ||= doc.at_css('meta[property="og:image"]')&.attr("content").presence

      data.compact
    end

    def apply_updates(data)
      updates = {}
      updates[:name]   = data[:name]   if data[:name].present? && @product.name != data[:name]
      updates[:weight] = data[:weight] if data[:weight].present? && @product.weight.nil?

      @product.update!(updates) if updates.any?

      # ActionText rich description — only set if currently blank
      if data[:description].present? && @product.description.body.blank?
        @product.description = data[:description]
        @product.save!
      end
    end
  end
end
