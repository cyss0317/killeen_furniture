require "net/http"

module ProductImport
  class GenerationTradeScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    BASE_URL = "https://generationtrade.com"

    HEADERS = {
      "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept"          => "application/json, text/html, */*",
      "Accept-Language" => "en-US,en;q=0.9"
    }.freeze

    def self.call(sku:, page_url: nil)
      new(sku, page_url:).call
    end

    def initialize(sku, page_url: nil)
      @sku      = sku.to_s.strip
      @page_url = page_url
    end

    def call
      # Try the exact product URL from the browser address bar first (most reliable)
      if @page_url&.match?(/generationtrade\.com/i)
        # Extract Shopify product handle from URL: /products/HANDLE
        handle = @page_url[/\/products\/([^\/?#]+)/, 1]
        if handle
          result = fetch_product_json(handle)
          return result if result
        end
      end

      # Shopify stores expose a public search JSON endpoint
      body = fetch_url("#{BASE_URL}/search.json?q=#{CGI.escape(@sku)}&type=product")
      if body
        json = JSON.parse(body) rescue nil
        if json
          products = json.dig("results") || json.dig("products") || []
          handle   = products.first&.dig("handle") || products.first&.dig("url")&.split("/products/")&.last
          if handle
            product_json = fetch_product_json(handle.to_s.split("?").first)
            return product_json if product_json
          end
        end
      end

      # Fallback: try the SKU directly as a product handle (lowercased, hyphenated)
      handle = @sku.downcase.gsub(/[^a-z0-9]+/, "-")
      product_json = fetch_product_json(handle)
      return product_json if product_json

      Result.new(image_urls: [], data: {}, error: "No images found for #{@sku} on Generation Trade website")
    rescue => e
      Result.new(error: "Generation Trade scraper: #{e.message}")
    end

    private

    # Shopify public product JSON: /products/[handle].json
    def fetch_product_json(handle)
      body = fetch_url("#{BASE_URL}/products/#{CGI.escape(handle)}.json")
      return nil unless body

      json    = JSON.parse(body) rescue nil
      product = json&.dig("product")
      return nil unless product

      images = Array(product["images"]).map { |img| img["src"].to_s.gsub(/\?.*\z/, "") }
                                       .select { |u| u.match?(/\Ahttps?:\/\//) }
                                       .first(8)
      return nil if images.empty?

      Result.new(image_urls: images, data: {
        name:              product["title"],
        description:       product["body_html"]&.gsub(/<[^>]+>/, " ")&.strip
      })
    end

    def fetch_url(url, depth = 3)
      return nil if depth.zero?

      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl:      uri.scheme == "https",
                      open_timeout: 8,
                      read_timeout: 12) do |http|
        req = Net::HTTP::Get.new(uri)
        HEADERS.each { |k, v| req[k] = v }
        res = http.request(req)

        case res
        when Net::HTTPSuccess
          res.body
        when Net::HTTPRedirection
          loc = res["location"].to_s
          loc = "#{BASE_URL}#{loc}" unless loc.start_with?("http")
          fetch_url(loc, depth - 1)
        end
      end
    rescue => e
      Rails.logger.warn("GenerationTradeScraper fetch #{url}: #{e.message}")
      nil
    end
  end
end
