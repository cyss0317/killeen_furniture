class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order,        null: false, foreign_key: true
      t.references :product,      null: true,  foreign_key: true
      t.integer    :quantity,     null: false, default: 1
      t.decimal    :unit_price,   null: false, precision: 10, scale: 2
      t.string     :product_name, null: false
      t.string     :product_sku,  null: false

      t.timestamps
    end
  end
end
