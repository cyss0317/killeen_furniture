class AddFreightCostToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :freight_cost, :decimal, precision: 10, scale: 2, default: 0
  end
end
