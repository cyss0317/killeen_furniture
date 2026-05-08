require "net/http"
require "json"
require "base64"

module Ashley
  # Fetches product data from the Ashley dealer API gateway.
  # Uses the JSON API discovered from the dealer portal Angular app —
  # no Selenium / headless browser required.
  #
  # Auth config (set in ENV):
  #   ASHLEY_DIRECT_COOKIES — JSON array of cookie objects exported from a
  #                           logged-in browser session on home.ashleydirect.com
  #
  # Falls back to probing cdn.ashley.com image URLs when the API is unreachable.
  class DirectScraper
    Result = Struct.new(:image_urls, :data, :error, keyword_init: true)

    API_BASE = "https://apigw3.ashleyfurniture.com/ashley-direct-catalog-experience/Catalog/product-detail"
    CDN_BASE = "https://cdn.ashley.com/assets"

    CDN_VIEWS = %w[
      SW-ID
      ANGLE-SW-P1-KO
      HEAD-ON-SW-P1-KO
      BACK-SW-P1-KO
      SIDE-SW-P1-KO
      CLSD-ANGLE-SW-P1-KO
    ].freeze

    def self.call(sku:)
      new(sku).call
    end

    # Debug helper — parse a raw JSON string without making a real HTTP call.
    # Usage: Ashley::DirectScraper.parse_json(raw_json_string, sku: "B376-92")
    def self.parse_json(raw, sku: "DEBUG")
      instance = new(sku)
      instance.send(:map_api_response, JSON.parse(raw))
    end

    def initialize(sku)
      @sku = sku.to_s.strip.upcase
    end

    def call
      log "▶ call started — credentials_configured=#{credentials_configured?}"

      if credentials_configured?
        json = fetch_from_api
        if json
          data = map_api_response(json)
          imgs = data.delete(:image_urls).map { |u| clean_cdn_url(u) }.uniq
          log "  API result: #{data.inspect}"
          log "  images: #{imgs.inspect}"
          return Result.new(image_urls: imgs, data: data) if imgs.any? || data[:name].present?
          log "  ⚠ API returned no name and no images — falling through to CDN"
        else
          log "  ✗ API fetch returned nil"
        end
      else
        log "  ⚠ no credentials — skipping API, going straight to CDN probe"
      end

      cdn_images = probe_cdn_images
      log "  CDN probe result: #{cdn_images.inspect}"
      return Result.new(image_urls: cdn_images, data: {}) if cdn_images.any?

      log "  ✗ nothing found for #{@sku}"
      Result.new(image_urls: [], error: "No data found for #{@sku}")
    rescue => e
      Rails.logger.error("[Ashley::DirectScraper] #{@sku}: #{e.class} — #{e.message}")
      Result.new(image_urls: [], error: e.message)
    end

    private

    def clean_sku
      @sku.sub(/\AAF-?/i, "")
    end

    def api_url
      "#{API_BASE}/#{clean_sku}?apikey=#{ENV['ASHLEY_API_KEY']}"
    end

    def api_body
      {
        customerDetails: {
          customerNumber:          ENV["ASHLEY_CUSTOMER_NUMBER"],
          shipTo:                  ENV.fetch("ASHLEY_SHIP_TO", ""),
          allShipTo:               true,
          environment:             ENV.fetch("ASHLEY_ENVIRONMENT", "AFI"),
          warehouse:               [ ENV.fetch("ASHLEY_WAREHOUSE", "28") ],
          checkWarehouseOverrides: true,
          noShowPricing:           false,
          securityAccesses: {
            customerEdiAuthorization:       true,
            customerServiceAuthorization:   false,
            marketingSpecialistAuthorization: false,
            homeStoreAuthorization:         false,
            aTPAuthorization:               true,
            mSEdiAuthorization:             false,
            hasPricingAuthorization:        true,
            isITAdmin:                      false,
            wishListAuthorization:          false,
            isMasterUser:                   false,
            relevanceSortPreview:           true,
            hideAshtonYork:                 false
          },
          channelId: "PRMRY"
        },
        includePrice: true,
        includeATP:   true,
        includeTags:  true,
        includeVideo: true
      }
    end

    def credentials_configured?
      ENV["ASHLEY_API_KEY"].present? && ENV["ASHLEY_CUSTOMER_NUMBER"].present?
    end

    def basic_auth_header
      encoded = Base64.strict_encode64("#{ENV['ASHLEY_DIRECT_EMAIL']}:#{ENV['ASHLEY_DIRECT_PASSWORD']}")
      "Basic #{encoded}"
    end

    # ── API call ─────────────────────────────────────────────────────────────

    def fetch_from_api
      uri = URI.parse(api_url)
      log "  API: POST #{uri}"

      req = Net::HTTP::Post.new(uri)
      req["Accept"]          = "application/json"
      req["Content-Type"]    = "application/json"
      req["Client_Id"]       = ENV["ASHLEY_CLIENT_ID"].to_s
      req["Origin"]          = "https://home.ashleydirect.com"
      req["Accept-Language"] = "en-us"
      req.body = api_body.to_json

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                            open_timeout: 10, read_timeout: 15) do |http|
        http.request(req)
      end

      log "  API: response #{res.code} (#{res.body&.bytesize} bytes)"

      return nil unless res.code == "200"
      JSON.parse(res.body)
    rescue => e
      log "  API: ✗ #{e.class} — #{e.message}"
      nil
    end

    # ── JSON → data hash ─────────────────────────────────────────────────────

    def map_api_response(json)
      data = { image_urls: [] }

      data[:name]        = json["friendlyDescription"].to_s.strip.presence ||
                           json["alternateDescription3"].to_s.strip.presence
      data[:sku]         = json["sku"]
      data[:status_text] = json["statusDescription"]
      data[:color]       = json["color"].to_s.strip.presence
      data[:style]       = json["style"].to_s.strip.presence
      data[:showroom]    = json["seriesShowroom"].to_s.strip.presence
      data[:division]    = json["divisionName"].to_s.strip.presence

      # Weight (lbs)
      data[:weight] = json["standardShippingWeight"].to_f if json["standardShippingWeight"].present?

      # Overall dimensions (inches)
      data[:dimensions_width]  = json["standardWidth"].to_f  if json["standardWidth"].present?
      data[:dimensions_depth]  = json["standardDepth"].to_f  if json["standardDepth"].present?
      data[:dimensions_height] = json["standardHeight"].to_f if json["standardHeight"].present?

      # Extra dimensions (drawer interiors, rail heights, etc.)
      if json["extraDimensions"].present?
        extra = json["extraDimensions"].each_with_object({}) do |d, h|
          label = d["dimensionDescription"].to_s.strip
          next if label.blank?

          w, depth, ht = d["standardWidth"].to_f, d["standardDepth"].to_f, d["standardHeight"].to_f
          alt = d["standardAlternateDim"].to_f

          value = if w > 0 || depth > 0 || ht > 0
            "#{w}\" W x #{depth}\" D x #{ht}\" H"
          elsif alt > 0
            "#{alt}\""
          end

          h[label] = value if value
        end
        data[:extra_dimensions] = extra if extra.any?
      end

      # Wholesale price (MESQUITE warehouse = warehouse 28)
      price_entry = Array(json["priceInfo"]).find { |p| p["warehouse"] == "28" } ||
                    Array(json["priceInfo"]).first
      data[:base_cost] = price_entry["itemPrice"].to_f if price_entry&.dig("itemPrice").present?

      # Description — paragraph + bullet points
      body    = json["itemDescription"].to_s.strip.presence
      bullets = Array(json["productDetails"]).map(&:strip).reject(&:blank?)
      parts   = [ body, bullets.map { |b| "• #{b}" }.join("\n") ].reject(&:blank?)
      data[:description] = parts.join("\n\n").presence

      # Images — prefer itemAFIImageSetLinks (same CDN), fall back to imageSet
      images = Array(json["itemAFIImageSetLinks"]).presence ||
               Array(json["imageSet"]).presence ||
               []
      data[:image_urls] = images.map { |u| u.to_s.gsub(/\?.*\z/, "") }.uniq

      # Series info
      data[:series_name]     = json["seriesName"].to_s.strip.presence
      data[:series_features] = json["seriesFeatures"].to_s.strip.presence
      data[:intended_room]   = Array(json["itemIntendedRoom"]).first.to_s.strip.presence

      # Videos — two formats depending on which API path returned them:
      #   videoInfo: series-level [{sheetName, videoLink (full URL)}]
      #   videos:    item-level   [{type, id (YouTube ID), key}]
      all_videos = []

      Array(json["videoInfo"]).each do |v|
        url = v["videoLink"].to_s
        all_videos << { title: v["sheetName"].to_s, url: url } if url.match?(/youtu/)
      end

      Array(json["videos"]).each do |v|
        next unless v["type"] == "YouTube" && v["id"].present?
        url = "https://youtu.be/#{v['id']}"
        all_videos << { title: v["key"].to_s.gsub(/([A-Z])/, ' \1').strip, url: url }
      end

      unique_videos = all_videos.uniq { |v| v[:url] }
      data[:videos] = unique_videos if unique_videos.any?

      # Documents — assembly instructions, parts drawings, mechanism guides
      documents = []
      Array(json["instructionList"]).each do |d|
        documents << { type: "Assembly Instructions", filename: d["filename"], url: d["url"] } if d["url"].present?
      end
      Array(json["partsDrawingList"]).each do |d|
        documents << { type: "Parts Drawing", filename: d["filename"], url: d["url"] } if d["url"].present?
      end
      Array(json["mechanismGuideList"]).each do |d|
        documents << { type: "Mechanism Guide", filename: d["filename"], url: d["url"] } if d["url"].present?
      end
      data[:documents] = documents if documents.any?

      data[:page_url] = "https://home.ashleydirect.com/catalog/product-detail/#{clean_sku}?warehouse=28&env=AFI"
      data
    end

    # ── CDN helpers ──────────────────────────────────────────────────────────

    def sku_cdn_prefix
      clean = clean_sku
      clean.match?(/\A\d{7,}\z/) ? "#{clean[0..-3]}-#{clean[-2..]}" : clean
    end

    def probe_cdn_images
      prefix     = sku_cdn_prefix
      candidates = CDN_VIEWS.map { |v| "#{CDN_BASE}/#{prefix}-#{v}.jpg" }
      candidates << "#{CDN_BASE}/#{prefix}.jpg"

      candidates.select { |url| head_ok?(url) }
                .map    { |url| "#{url}?height=1000" }
    end

    def head_ok?(url)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                      open_timeout: 3, read_timeout: 3) do |http|
        http.head(uri.request_uri).code == "200"
      end
    rescue
      false
    end

    def clean_cdn_url(url)
      "#{url.gsub(/\?.*\z/, "")}?height=1000"
    end

    def log(msg)
      Rails.logger.info("[Ashley::DirectScraper] #{msg}")
    end
  end
end
