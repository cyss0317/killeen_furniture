class AddVendorImageUrlsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :vendor_image_urls, :string, array: true, default: []
  end
end
