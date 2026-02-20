class AddPricingSnapshotsToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_column :order_items, :unit_cost,         :decimal, precision: 10, scale: 2
    add_column :order_items, :markup_percentage, :decimal, precision: 5,  scale: 2
  end
end
