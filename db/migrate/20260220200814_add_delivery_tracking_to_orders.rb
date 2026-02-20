class AddDeliveryTrackingToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :source,          :integer, default: 0, null: false
    add_column :orders, :assigned_to_id,  :bigint
    add_column :orders, :delivered_by_id, :bigint
    add_column :orders, :delivered_at,    :datetime
    add_index  :orders, :assigned_to_id
    add_index  :orders, :delivered_at
    add_foreign_key :orders, :users, column: :assigned_to_id
    add_foreign_key :orders, :users, column: :delivered_by_id
  end
end
