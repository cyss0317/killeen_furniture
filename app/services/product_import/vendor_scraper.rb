module ProductImport
  class VendorScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    def self.call(sku:, brand:)
      new(sku:, brand:).call
    end

    def initialize(sku:, brand:)
      @sku   = sku.to_s.strip
      @brand = brand.to_s
    end

    def call
      scraper_class = if @brand.match?(/ashley/i)
        AshleyScraper
      elsif @brand.match?(/generation.?trade/i)
        GenerationTradeScraper
      end

      return Result.new(error: "Unsupported vendor: #{@brand}") unless scraper_class

      scraper_class.call(sku: @sku)
    rescue => e
      Result.new(error: e.message)
    end
  end
end
