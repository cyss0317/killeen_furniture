class AddBrandToPurchaseOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_order_items, :brand, :string
  end
end
