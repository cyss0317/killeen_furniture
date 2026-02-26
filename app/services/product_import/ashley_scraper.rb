require "net/http"
require "nokogiri"

module ProductImport
  class AshleyScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    BASE_URL = "https://www.ashleyfurniture.com"

    HEADERS = {
      "User-Agent"                => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      "Accept"                    => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language"           => "en-US,en;q=0.9",
      "Accept-Encoding"           => "gzip, deflate, br",
      "Cache-Control"             => "max-age=0",
      "Sec-Ch-Ua"                 => '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
      "Sec-Ch-Ua-Mobile"          => "?0",
      "Sec-Ch-Ua-Platform"        => '"macOS"',
      "Sec-Fetch-Dest"            => "document",
      "Sec-Fetch-Mode"            => "navigate",
      "Sec-Fetch-Site"            => "none",
      "Sec-Fetch-User"            => "?1",
      "Upgrade-Insecure-Requests" => "1"
    }.freeze

    def self.call(sku:, page_url: nil)
      new(sku, page_url:).call
    end

    def initialize(sku, page_url: nil)
      @sku      = sku.to_s.strip.gsub(/\AAF-?\s*/i, "") # Remove 'AF-' or 'AF ' prefix
      @page_url = page_url
    end

    def call
      # Try the exact product URL from the browser address bar first (most reliable)
      if @page_url&.match?(/ashleyfurniture\.com/i)
        html = fetch_url(@page_url)
        if html
          doc  = Nokogiri::HTML(html)
          data = extract_product_info(doc)
          return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any?
        end
      end

      # Try direct product URL using SKU
      html = fetch_url("#{BASE_URL}/p/-/#{CGI.escape(@sku)}/")
      if html
        doc  = Nokogiri::HTML(html)
        data = extract_product_info(doc)
        return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any?
      end

      # Fallback: search page → follow first product link
      html = fetch_url("#{BASE_URL}/search-results?q=#{CGI.escape(@sku)}")
      if html
        doc  = Nokogiri::HTML(html)
        link = doc.at_css("a[href$='#{@sku}.html']")
        if link
          product_url = link["href"].start_with?("http") ? link["href"] : "#{BASE_URL}#{link["href"]}"
          Rails.logger.info("Product URL: #{product_url}")
          html = fetch_url(product_url)
          # binding.pry
          if html
            doc  = Nokogiri::HTML(html)
            data = extract_product_info(doc)
            return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any?
          end
        end
      end

      # Fallback 2: Scene7 CDN pattern fallback (Very robust for Ashley)
      # Detailed suffixes for specific views (CLSD-ANGLE, HEAD-ON, SIDE, BACK)
      suffixes = [
        "", "-1", "-2", "-3", "-ANGLE", "-ROOM",
        "-CLSD-ANGLE-SW-P1-KO", "-HEAD-ON-SW-P1-KO", "-SIDE-SW-P1-KO", "-BACK-SW-P1-KO",
        "-DIM"
      ]
      imgs = suffixes.map { |s| "https://ashleyfurniture.scene7.com/is/image/AshleyFurniture/#{@sku}#{s}?wid=1200&hei=900" }

      # Handle {SERIES}-SWATCH-500 (e.g., B2589-SWATCH-500)
      series = @sku.split("-").first
      if series && series != @sku
        imgs << "https://ashleyfurniture.scene7.com/is/image/AshleyFurniture/#{series}-SWATCH-500?wid=500&hei=500"
      end

      # Also try the numeric pattern if it looks like a 7+ digit SKU
      if @sku.match?(/\A\d{7,}\z/)
        imgs += (1..5).map { |i| "https://images.ashleyfurniture.com/render/item/#{@sku}-#{i}.jpg" }
      end

      return Result.new(image_urls: imgs.uniq, error: "Cloudflare blocked scrape; using Scene7 pattern fallback")

      # If all scrapers failed and no pattern fallback
      Result.new(image_urls: [], error: "No images found for #{@sku} on Ashley Furniture website")
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

        # binding.pry
        case res
        when Net::HTTPSuccess
          res.body
        when Net::HTTPRedirection
          loc = res["location"].to_s
          loc = "#{BASE_URL}#{loc}" unless loc.start_with?("http")
          fetch_url(loc, depth - 1)
        else
          Rails.logger.warn("AshleyScraper: HTTP #{res.code} for #{url}")
          nil
        end
      end
    rescue => e
      Rails.logger.warn("AshleyScraper fetch #{url}: #{e.message}")
      nil
    end

    def extract_product_info(doc)
      data = { image_urls: [] }

      # 1) JSON-LD schema.org Product
      doc.css('script[type="application/ld+json"]').each do |script|
        json = JSON.parse(script.text.strip) rescue next
        records = json.is_a?(Hash) && json["@graph"] ? Array(json["@graph"]) : Array(json)

        product = records.find { |rec| rec.is_a?(Hash) && rec["@type"] == "Product" }
        next unless product

        data[:name]        = product["name"].to_s.presence
        data[:description] = product["description"].to_s.presence
        data[:image_urls]  = Array(product["image"]).map { |img| img.is_a?(Hash) ? (img["url"] || img["contentUrl"]).to_s : img.to_s }
                                                  .select { |u| u.match?(/\Ahttps?:\/\//) }
        break if data[:image_urls].any?
      end

      # 2) Image tag fallbacks if JSON-LD missed them
      if data[:image_urls].empty?
        data[:image_urls] = extract_images(doc)
      end

      data[:image_urls] = data[:image_urls].first(8)
      data
    end

    def extract_images(doc)
      # Open Graph image tags
      og = doc.css('meta[property="og:image"], meta[name="og:image"]').map { |m| m["content"].to_s }
              .select { |u| u.match?(/\Ahttps?:\/\//) }
      return og if og.any?

      # Ashley CDN image tags
      doc.css("img[src]").map { |img|
        img["data-zoom-image"] || img["data-src"] || img["src"]
      }.select { |u|
        u.to_s.match?(/\Ahttps?:\/\/(cdn|s7d2|images|ashleyfurniture\.scene7)\.ashleyfurniture\.com|akamaized\.net/i)
      }.uniq
    end
  end
end
