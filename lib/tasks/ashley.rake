namespace :ashley do
  desc "Sync Ashley products by sku. Usage: rake ashley:sync_product[SKU123]"
  task :sync_product, [:sku] => :environment do |_, args|
    sku = args[:sku]
    if sku.blank?
      puts "Please provide a SKU. Example: rake ashley:sync_product[SKU123]"
      exit
    end

    puts "Starting sync for SKU: #{sku}..."
    begin
      Ashley::ProductSyncService.new(sku).call
      puts "Successfully synced SKU: #{sku}"
    rescue => e
      puts "Failed to sync SKU: #{sku}. Error: #{e.message}"
    end
  end
end
