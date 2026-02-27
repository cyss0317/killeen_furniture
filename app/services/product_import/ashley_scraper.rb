require "net/http"
require "nokogiri"
require "json"

module ProductImport
  class AshleyScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    BASE_URL = "https://www.ashleyfurniture.com"

    HEADERS = {
      "User-Agent"                => "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      "Accept"                    => "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
      "Accept-Language"           => "en-US,en;q=0.9",
      "Accept-Encoding"           => "gzip, deflate, br",
      "Cache-Control"             => "no-cache",
      "Pragma"                    => "no-cache",
      "Sec-Ch-Ua"                 => '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
      "Sec-Ch-Ua-Mobile"          => "?0",
      "Sec-Ch-Ua-Platform"        => '"Windows"',
      "Sec-Fetch-Dest"            => "document",
      "Sec-Fetch-Mode"            => "navigate",
      "Sec-Fetch-Site"            => "none",
      "Sec-Fetch-User"            => "?1",
      "Upgrade-Insecure-Requests" => "1",
      "Connection"                => "keep-alive"
    }.freeze

    def self.call(sku:, page_url: nil)
      new(sku, page_url:).call
    end

    def initialize(sku, page_url: nil)
      @sku      = sku.to_s.strip.gsub(/\AAF-?\s*/i, "") # Remove 'AF-' or 'AF ' prefix
      @page_url = page_url
    end

    def call
      # 1) Try Constructor.io API first (fastest and unblocked)
      if @sku.present?
        c_data = fetch_from_constructor
        if c_data && (c_data[:description].present? || c_data[:image_urls].any?)
          # Successfully got data from Constructor.io
          # Still try Scene7 for more images since Constructor often only has one
          s7_images = fetch_scene7_images
          c_data[:image_urls] = (c_data[:image_urls] + s7_images).uniq.first(8)

          return Result.new(image_urls: c_data[:image_urls], data: c_data.except(:image_urls))
        end
      end

      # 2) Try the exact product URL from the browser address bar (if provided)
      if @page_url&.match?(/ashleyfurniture\.com/i)
        html = fetch_url(@page_url)
        if html
          doc  = Nokogiri::HTML(html)
          data = extract_product_info(doc)
          return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any? || data[:description].present?
        end
      end

      # 3) Fallback: direct product URL using SKU patterns
      ["#{BASE_URL}/p/-/#{CGI.escape(@sku)}/", "#{BASE_URL}/p/-/#{@sku}.html"].each do |url|
        html = fetch_url(url)
        if html
          doc  = Nokogiri::HTML(html)
          data = extract_product_info(doc)
          return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any? || data[:description].present?
        end
      end

      # 4) Fallback: search page (highly likely to be 403)
      html = fetch_url("#{BASE_URL}/search-results?q=#{CGI.escape(@sku)}")
      if html
        doc  = Nokogiri::HTML(html)
        link = doc.at_css("a[href*='#{@sku}.html']") || doc.at_css("a[href*='/p/']")
        if link
          product_url = link["href"].start_with?("http") ? link["href"] : "#{BASE_URL}#{link["href"]}"
          html = fetch_url(product_url)
          if html
            doc  = Nokogiri::HTML(html)
            data = extract_product_info(doc)
            return Result.new(image_urls: data[:image_urls], data: data.except(:image_urls)) if data[:image_urls].any? || data[:description].present?
          end
        end
      end

      # 5) Last Fallback: Scene7 CDN pattern matching (Very robust for Ashley)
      imgs = fetch_scene7_images
      if imgs.any?
        return Result.new(image_urls: imgs.uniq.first(8), error: "Main site blocked; using Scene7 fallback")
      end

      Result.new(image_urls: [], error: "No images or data found for #{@sku} on Ashley Furniture website")
    rescue => e
      Result.new(error: "Ashley scraper: #{e.message}")
    end

    private

    def fetch_from_constructor
      key = "key_K0xLx6sleKg7RBXp"
      url = "https://pwcdauseo-zone.cnstrc.com/autocomplete/#{CGI.escape(@sku)}?key=#{key}"

      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 5) do |http|
        req = Net::HTTP::Get.new(uri)
        req["User-Agent"] = HEADERS["User-Agent"]
        req["Accept"] = "application/json"

        res = http.request(req)
        return nil unless res.code == "200"

        json = JSON.parse(res.body)
        products = json.dig("sections", "Products")
        return nil if products.blank?

        product = products.first
        data_attr = product["data"] || {}

        # Map Constructor.io data to our internal format
        {
          name: product["value"].to_s.presence,
          description: data_attr["description"].to_s.presence&.gsub(" | ", "\n\n"),
          brand: data_attr["brand"].to_s.presence || "Ashley Furniture",
          dimensions_width: data_attr["productWidthIn"]&.to_f,
          dimensions_height: data_attr["productHeightIn"]&.to_f,
          dimensions_depth: data_attr["productDepthIn"]&.to_f,
          weight: data_attr["unitWeightLbs"]&.to_f,
          image_urls: [product["matched_url"] || data_attr["imageUrl"]].compact
        }
      end
    rescue => e
      Rails.logger.warn("AshleyScraper: Constructor.io fetch failed: #{e.message}")
      nil
    end

    def fetch_scene7_images
      suffixes = [
        "", "-1", "-2", "-3", "-ANGLE", "-ROOM", "-CLSD-ANGLE-SW-P1-KO",
        "-ANGLE-SW-P1-KO", "-ANGLE-NM-SW-P1-KO", "-ANGLE-ALT-SW-P1-KO",
        "-CLSD-ANGLE-SW-P1-KO", "-HEAD-ON-SW-P1-KO", "-SIDE-SW-P1-KO",
        "-SIDE-ALT-SW-P1-KO", "-BACK-SW-P1-KO", "-HDBD-DETAIL", "-DIM"
      ]
      imgs = suffixes.map { |s| "https://ashleyfurniture.scene7.com/is/image/AshleyFurniture/#{@sku}#{s}?wid=1200&hei=900" }
      imgs.select! do |url|
        uri = URI.parse(url)
        Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 2, read_timeout: 2) do |http|
          http.head(uri.request_uri).code == "200"
        end
      rescue
        false
      end

      # Handle {SERIES} swatches and finishes
      series = @sku.split("-").first
      if series && series != @sku
        imgs << "https://ashleyfurniture.scene7.com/is/image/AshleyFurniture/#{series}-SWATCH-500?wid=500&hei=500"
        imgs << "https://ashleyfurniture.scene7.com/is/image/AshleyFurniture/#{series}-FINISH-500?wid=500&hei=500"
      end

      # Also try the numeric pattern
      if @sku.match?(/\A\d{7,}\z/)
        imgs += (1..5).map { |i| "https://images.ashleyfurniture.com/render/item/#{@sku}-#{i}.jpg" }
      end

      imgs.uniq
    end

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

      # 2) Modern Accordion-based layout (Description and Dimensions)
      doc.css(".accordion").each do |accordion|
        header_text = accordion.at_css(".accordion-header")&.text.to_s.strip
        content     = accordion.at_css(".accordion-content")

        if header_text.match?(/Details & Overview/i)
          details_container = content&.at_css(".pdp-details-overview")
          if details_container
            desc_h3 = details_container.at_css("h3")
            if desc_h3 && desc_h3.text.strip.match?(/Description/i)
              main_desc_el = desc_h3.next_element
              if main_desc_el&.name == "p"
                main_text = main_desc_el.text.strip
                data[:description] = main_text
                if data[:color].blank?
                  if (match = main_text.match(/([^.]+)\s+(?:finish|color)[\s.]/i))
                    data[:color] = match[1].strip
                  end
                end
              end
            end

            bullets = details_container.css("ul li p").map(&:text).map(&:strip)
            if bullets.any?
              data[:description] = [data[:description], bullets.map { |b| "• #{b}" }.join("\n")].compact.join("\n\n")
              data[:material] ||= bullets.find { |b| b.match?(/Made of|Material:/i) }&.gsub(/Made of|Material:/i, "")&.strip
              data[:color]    ||= bullets.find { |b| b.match?(/Color:|Finish:/i) }&.gsub(/Color:|Finish:/i, "")&.strip
            end
          end
        elsif header_text.match?(/Dimensions/i)
          dim_text = content&.text.to_s.strip
          data = data.merge(parse_dimension_text(dim_text)) if dim_text.present?
          data[:material] ||= dim_text.match(/Material:\s*([^"(\n\r]+)/i)&.captures&.first&.strip
          data[:color]    ||= dim_text.match(/Color:\s*([^"(\n\r]+)/i)&.captures&.first&.strip
        end
      end

      # 3) Image tag fallbacks if JSON-LD missed them
      data[:image_urls] = extract_images(doc) if data[:image_urls].empty?
      data[:image_urls] = data[:image_urls].first(8)
      data
    end

    def parse_dimension_text(text)
      dims = {}
      if (match = text.match(/Width:\s*([\d.]+)/i) || text.match(/([\d.]+)"\s*W/i))
        dims[:dimensions_width] = match[1].to_f
      end
      if (match = text.match(/Height:\s*([\d.]+)/i) || text.match(/([\d.]+)"\s*H/i))
        dims[:dimensions_height] = match[1].to_f
      end
      if (match = text.match(/Depth:\s*([\d.]+)/i) || text.match(/([\d.]+)"\s*D/i))
        dims[:dimensions_depth] = match[1].to_f
      end
      if (match = text.match(/Weight:\s*([\d.]+)/i) || text.match(/([\d.]+)\s*lbs/i))
        dims[:weight] = match[1].to_f
      end
      dims
    end

    def extract_images(doc)
      urls = []
      doc.css("img").each do |img|
        [img["src"], img["data-src"], img["data-zoom-image"]].each do |u|
          urls << u if u.to_s.match?(/\Ahttps?:\/\/.*(ashleyfurniture|scene7|akamaized)/i)
        end
        if img["srcset"].present?
          img["srcset"].split(",").each do |src_part|
            u = src_part.strip.split(/\s+/).first
            urls << u if u.to_s.match?(/\Ahttps?:\/\/.*(ashleyfurniture|scene7|akamaized)/i)
          end
        end
      end
      doc.css('meta[property="og:image"], meta[name="og:image"]').each do |meta|
        u = meta["content"].to_s
        urls << u if u.match?(/\Ahttps?:\/\//)
      end
      urls.compact.map { |u| u.gsub(/\?.*\z/, "") }.uniq
    end
  end
end
