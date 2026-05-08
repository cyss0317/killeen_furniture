module Products
  # Best-effort enrichment of a product record using data scraped from
  # home.ashleydirect.com via Ashley::DirectScraper.
  # Failures are silently swallowed — this is always optional enrichment,
  # never blocking.
  class FetchFromAshley
    def self.enrich!(product, series: nil, description: nil)
      new(product: product).enrich!
    end

    def initialize(product:)
      @product = product
    end

    def enrich!
      log "▶ enrich! sku=#{@product.sku} id=#{@product.id}"
      result = Ashley::DirectScraper.call(sku: @product.sku)

      log "  scraper returned: images=#{result.image_urls.size} data_keys=#{result.data&.keys.inspect} error=#{result.error.inspect}"

      if result.image_urls.empty? && result.data.to_h.empty?
        log "  ✗ nothing returned — skipping update"
        return false
      end

      apply_updates((result.data || {}).merge(image_urls: result.image_urls))
      true
    rescue => e
      Rails.logger.warn "[FetchFromAshley] #{@product.sku}: #{e.class} — #{e.message}"
      false
    end

    private

    def apply_updates(data)
      tag     = "[FetchFromAshley] #{@product.sku}"
      updates = {}

      log "#{tag} apply_updates — incoming data keys: #{data.keys.inspect}"

      # Name
      if data[:name].present? && @product.name != data[:name]
        updates[:name] = data[:name]
        log "#{tag}   → name: #{@product.name.inspect} → #{data[:name].inspect}"
      else
        log "#{tag}   name skipped (scrape=#{data[:name].inspect}, existing=#{@product.name.inspect})"
      end

      # Weight
      if data[:weight].present? && @product.weight.nil?
        updates[:weight] = data[:weight]
        log "#{tag}   → weight: #{data[:weight]}"
      else
        log "#{tag}   weight skipped (scrape=#{data[:weight].inspect}, existing=#{@product.weight.inspect})"
      end

      updates[:page_url] = data[:page_url] if data[:page_url].present? && @product.page_url.blank?
      updates[:brand]    = "Ashley Furniture" if @product.brand.blank? || !@product.brand.match?(/ashley/i)

      if data[:color].present? && @product.color.blank?
        updates[:color] = data[:color]
        log "#{tag}   → color: #{data[:color].inspect}"
      end

      updates[:base_cost] = data[:base_cost] if data[:base_cost].present? && @product.base_cost.nil?

      # Dimensions
      if data[:dimensions_width].present? || data[:dimensions_height].present? || data[:dimensions_depth].present?
        new_dims = (@product.dimensions || {}).dup
        new_dims["width"]  = data[:dimensions_width]  if data[:dimensions_width].present?
        new_dims["height"] = data[:dimensions_height] if data[:dimensions_height].present?
        new_dims["depth"]  = data[:dimensions_depth]  if data[:dimensions_depth].present?
        if new_dims != @product.dimensions
          updates[:dimensions] = new_dims
          log "#{tag}   → dimensions: #{new_dims.inspect}"
        end
      else
        log "#{tag}   dimensions skipped (scrape W=#{data[:dimensions_width]} D=#{data[:dimensions_depth]} H=#{data[:dimensions_height]})"
      end

      # Images
      if data[:image_urls].present? && @product.vendor_image_urls.blank?
        updates[:vendor_image_urls] = data[:image_urls]
        log "#{tag}   → vendor_image_urls: #{data[:image_urls].size} URLs"
      else
        log "#{tag}   images skipped (scrape=#{data[:image_urls]&.size || 0}, existing=#{@product.vendor_image_urls&.size || 0})"
      end

      # Description
      desc_blank = @product.description.body.blank? rescue @product.description.blank?
      if data[:description].present? && desc_blank
        updates[:description] = data[:description]
        log "#{tag}   → description: #{data[:description].first(60).inspect}"
      else
        log "#{tag}   description skipped (scrape present=#{data[:description].present?}, existing blank=#{desc_blank})"
      end

      # Persist Ashley metadata into the ashley_payload JSONB column
      ashley_meta = {}
      ashley_meta["style"]           = data[:style]           if data[:style].present?
      ashley_meta["showroom"]        = data[:showroom]        if data[:showroom].present?
      ashley_meta["division"]        = data[:division]        if data[:division].present?
      ashley_meta["status"]          = data[:status_text]     if data[:status_text].present?
      ashley_meta["extra_dimensions"]= data[:extra_dimensions] if data[:extra_dimensions].present?
      ashley_meta["series_name"]     = data[:series_name]     if data[:series_name].present?
      ashley_meta["series_features"] = data[:series_features] if data[:series_features].present?
      ashley_meta["intended_room"]   = data[:intended_room]   if data[:intended_room].present?
      ashley_meta["videos"]          = data[:videos]          if data[:videos].present?
      ashley_meta["documents"]       = data[:documents]       if data[:documents].present?

      if ashley_meta.any?
        updates[:ashley_payload] = (@product.ashley_payload || {}).merge(ashley_meta)
      end

      log "#{tag}   final updates keys: #{updates.keys.inspect}"
      @product.update!(updates) if updates.any?
    end

    def log(msg)
      Rails.logger.info("[FetchFromAshley] #{msg}")
    end
  end
end
