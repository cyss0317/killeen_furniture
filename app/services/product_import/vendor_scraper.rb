require "net/http"

module ProductImport
  class VendorScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    URL_TIMEOUT = 3

    def self.call(sku:, brand:, page_url: nil)
      new(sku:, brand:, page_url:).call
    end

    def initialize(sku:, brand:, page_url: nil)
      @sku      = sku.to_s.strip
      @brand    = brand.to_s
      @page_url = page_url
    end

    def call
      scraper_class = if @brand.match?(/ashley/i)
        AshleyScraper
      elsif @brand.match?(/generation.?trade/i)
        GenerationTradeScraper
      end

      return Result.new(error: "Unsupported vendor: #{@brand}") unless scraper_class

      result = scraper_class.call(sku: @sku, page_url: @page_url)

      # Drop any URLs that don't actually return a successful HTTP response.
      # Scene7 URLs are pre-validated in AshleyScraper, but Constructor.io and
      # HTML-scraped URLs are not — this catches them all in one place.
      verified = result.image_urls.to_a.select { |url| reachable?(url) }
      Result.new(image_urls: verified, data: result.data, error: result.error)
    rescue => e
      Result.new(error: e.message)
    end

    private

    def reachable?(url)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl:      uri.scheme == "https",
                      open_timeout: URL_TIMEOUT,
                      read_timeout: URL_TIMEOUT) do |http|
        http.head(uri.request_uri).is_a?(Net::HTTPSuccess)
      end
    rescue
      false
    end
  end
end
