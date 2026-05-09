class AddDiscountToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :discount, :decimal, precision: 10, scale: 2, default: 0
  end
end
