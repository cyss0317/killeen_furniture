class RemoveBrandFromPurchaseOrderItems < ActiveRecord::Migration[8.0]
  def up
    remove_column :purchase_order_items, :brand if column_exists?(:purchase_order_items, :brand)
  end

  def down
    add_column :purchase_order_items, :brand, :string unless column_exists?(:purchase_order_items, :brand)
  end
end
