module Ashley
  class ProductSyncService
    attr_reader :sku, :client

    def initialize(sku)
      @sku = sku
      @client = Ashley::Client.new
    end

    def call
      begin
        product_data = client.get_product(sku)
        sync_furniture(product_data)
      rescue Ashley::Client::Error => e
        Rails.logger.error("[Ashley::ProductSyncService] Error syncing SKU #{sku}: #{e.message}")
        raise e
      end
    end

    private

    def sync_furniture(product_data)
      product = Product.find_or_initialize_by(sku: sku)

      # Map payload to Product attributes, handling missing fields safely
      # We use 'fetch' or conditional assignment to not overwrite with nil if already present,
      # but if the API sends nil, it might overwrite. Let's use `|| existing` approach.
      product.name = product_data['name'] || product.name
      product.description = product_data['description'] || product.description
      product.brand = product_data['brand'] || product.brand
      product.collection = product_data['collection'] || product.collection
      product.category = product_data['category'] || product.category
      product.material = product_data['material'] || product.material
      product.color = product_data['color'] || product.color
      product.dimensions = product_data['dimensions'] || product.dimensions
      product.price = product_data['price'] || product.price

      # Extract array of image URLs
      images = product_data['images'] || []
      product.vendor_image_urls = images.map { |img| img['url'] }.compact

      # Store raw payload
      product.ashley_payload = product_data

      if product.save
        Rails.logger.info("[Ashley::ProductSyncService] Successfully synced SKU #{sku}")
        product
      else
        Rails.logger.error("[Ashley::ProductSyncService] Failed to save SKU #{sku}: #{product.errors.full_messages.join(', ')}")
        raise ActiveRecord::RecordInvalid.new(product)
      end
    end
  end
end
