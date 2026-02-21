class CreatePurchaseOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_order_items do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.references :product,        null: false, foreign_key: true
      t.integer :quantity_ordered,  null: false, default: 1
      t.integer :quantity_received, null: false, default: 0
      t.decimal :unit_cost, precision: 10, scale: 2, null: false
      t.string  :product_name, null: false
      t.string  :product_sku,  null: false

      t.timestamps
    end
  end
end
