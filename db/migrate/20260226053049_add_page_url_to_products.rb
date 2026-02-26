class AddPageUrlToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :page_url, :string
  end
end
