class AddPickupToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :pickup, :boolean, default: false, null: false
  end
end
