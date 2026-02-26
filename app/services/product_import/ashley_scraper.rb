require "net/http"
require "nokogiri"

module ProductImport
  class AshleyScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    BASE_URL = "https://www.ashleyfurniture.com"

    HEADERS = {
      "User-Agent"      => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
      "Accept"          => "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
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
      if @page_url&.match?(/ashleyfurniture\.com/i)
        html = fetch_url(@page_url)
        if html
          doc  = Nokogiri::HTML(html)
          imgs = extract_images(doc)
          return Result.new(image_urls: imgs, data: {}) if imgs.any?
        end
      end

      # Try direct product URL using SKU
      html = fetch_url("#{BASE_URL}/p/-/#{CGI.escape(@sku)}/")
      if html
        doc  = Nokogiri::HTML(html)
        imgs = extract_images(doc)
        return Result.new(image_urls: imgs, data: {}) if imgs.any?
      end

      # Fallback: search page → follow first product link
      html = fetch_url("#{BASE_URL}/search/?q=#{CGI.escape(@sku)}")
      if html
        doc  = Nokogiri::HTML(html)
        link = doc.at_css("a[href*='/p/']")
        if link
          product_url = link["href"].start_with?("http") ? link["href"] : "#{BASE_URL}#{link["href"]}"
          html = fetch_url(product_url)
          if html
            doc  = Nokogiri::HTML(html)
            imgs = extract_images(doc)
            return Result.new(image_urls: imgs, data: {}) if imgs.any?
          end
        end
      end

      Result.new(image_urls: [], data: {}, error: "No images found for #{@sku} on Ashley Furniture website")
    rescue => e
      Result.new(error: "Ashley scraper: #{e.message}")
    end

    private

    def fetch_url(url, depth = 4)
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
      Rails.logger.warn("AshleyScraper fetch #{url}: #{e.message}")
      nil
    end

    def extract_images(doc)
      # 1) JSON-LD schema.org Product (handles both array and @graph formats)
      doc.css('script[type="application/ld+json"]').each do |script|
        json = JSON.parse(script.text.strip) rescue next
        records = if json.is_a?(Hash) && json["@graph"]
          Array(json["@graph"])
        else
          Array(json)
        end
        records.each do |rec|
          next unless rec.is_a?(Hash) && rec["@type"] == "Product"
          imgs = Array(rec["image"]).map { |img| img.is_a?(Hash) ? (img["url"] || img["contentUrl"]).to_s : img.to_s }
                                    .select { |u| u.match?(/\Ahttps?:\/\//) }
          return imgs.first(8) if imgs.any?
        end
      end

      # 2) Open Graph image tags (usually at least 1 is present in SSR HTML)
      og = doc.css('meta[property="og:image"], meta[name="og:image"]').map { |m| m["content"].to_s }
              .select { |u| u.match?(/\Ahttps?:\/\//) }
      return og.first(8) if og.any?

      # 3) Ashley CDN image tags — look for images from ashley CDN domains
      cdn_imgs = doc.css("img[src]").map { |img|
        img["data-zoom-image"] || img["data-src"] || img["src"]
      }.select { |u|
        u.to_s.match?(/\Ahttps?:\/\/(cdn|s7d2|images)\.ashleyfurniture\.com|akamaized\.net/i)
      }.uniq.first(8)
      return cdn_imgs if cdn_imgs.any?

      []
    end
  end
end
