class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string     :name,              null: false
      t.string     :brand
      t.string     :sku,               null: false
      t.string     :slug,              null: false
      t.references :category,          null: false, foreign_key: true
      t.text       :short_description
      t.decimal    :base_cost,         null: false, precision: 10, scale: 2
      t.decimal    :markup_percentage, null: false, precision: 5,  scale: 2, default: 0
      t.decimal    :selling_price,     null: false, precision: 10, scale: 2, default: 0
      t.integer    :stock_quantity,    null: false, default: 0
      t.integer    :status,            null: false, default: 0
      t.boolean    :featured,          default: false
      t.decimal    :weight,            precision: 8, scale: 2
      t.jsonb      :dimensions,        default: {}
      t.string     :material
      t.string     :color

      t.timestamps
    end

    add_index :products, :sku,          unique: true
    add_index :products, :slug,         unique: true
    add_index :products, :status
    add_index :products, :featured
    add_index :products, :selling_price
    add_index :products, :dimensions,   using: :gin
  end
end
