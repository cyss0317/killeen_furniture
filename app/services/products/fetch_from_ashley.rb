module Products
  # Best-effort enrichment of a product record using data from Ashley::DealerApi.
  # Failures are silently swallowed — this is always optional enrichment, never blocking.
  class FetchFromAshley
    def self.enrich!(product, series: nil, description: nil)
      new(product: product).enrich!
    end

    def initialize(product:)
      @product = product
    end

    def enrich!
      result = Ashley::DealerApi.call(sku: @product.sku)
      return false if result.image_urls.empty? && result.data.to_h.empty?

      apply_updates((result.data || {}).merge(image_urls: result.image_urls))
      true
    rescue => e
      Rails.logger.warn "[FetchFromAshley] #{@product.sku}: #{e.class} — #{e.message}"
      false
    end

    private

    def apply_updates(data)
      updates = {}

      updates[:name]     = data[:name]     if data[:name].present?
      updates[:weight]   = data[:weight]   if data[:weight].present? && @product.weight.nil?
      updates[:page_url] = data[:page_url] if data[:page_url].present? && @product.page_url.blank?
      updates[:brand]    = "Ashley Furniture" if @product.brand.blank? || !@product.brand.match?(/ashley/i)
      updates[:color]    = data[:color]    if data[:color].present? && @product.color.blank?
      updates[:base_cost] = data[:base_cost] if data[:base_cost].present? && @product.base_cost.nil?

      if data[:dimensions_width].present? || data[:dimensions_height].present? || data[:dimensions_depth].present?
        new_dims = (@product.dimensions || {}).dup
        new_dims["width"]  = data[:dimensions_width]  if data[:dimensions_width].present?
        new_dims["height"] = data[:dimensions_height] if data[:dimensions_height].present?
        new_dims["depth"]  = data[:dimensions_depth]  if data[:dimensions_depth].present?
        updates[:dimensions] = new_dims if new_dims != @product.dimensions
      end

      if data[:image_urls].present? && @product.vendor_image_urls.blank?
        updates[:vendor_image_urls] = data[:image_urls]
      end

      desc_blank = @product.description.body.blank? rescue @product.description.blank?
      updates[:description] = data[:description] if data[:description].present? && desc_blank

      ashley_meta = {}
      ashley_meta["style"]            = data[:style]            if data[:style].present?
      ashley_meta["showroom"]         = data[:showroom]         if data[:showroom].present?
      ashley_meta["division"]         = data[:division]         if data[:division].present?
      ashley_meta["status"]           = data[:status_text]      if data[:status_text].present?
      ashley_meta["extra_dimensions"] = data[:extra_dimensions] if data[:extra_dimensions].present?
      ashley_meta["series_name"]      = data[:series_name]      if data[:series_name].present?
      ashley_meta["series_features"]  = data[:series_features]  if data[:series_features].present?
      ashley_meta["intended_room"]              = data[:intended_room]              if data[:intended_room].present?
      ashley_meta["group_description"]          = data[:group_description]          if data[:group_description].present?
      ashley_meta["default_navigable_category"] = data[:default_navigable_category] if data[:default_navigable_category].present?
      ashley_meta["videos"]           = data[:videos]           if data[:videos].present?
      ashley_meta["documents"]        = data[:documents]        if data[:documents].present?

      updates[:ashley_payload] = (@product.ashley_payload || {}).merge(ashley_meta) if ashley_meta.any?

      @product.update!(updates) if updates.any?
    end
  end
end
