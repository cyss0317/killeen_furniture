class CreateDeliveryZones < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_zones do |t|
      t.string  :name,                 null: false
      t.string  :zip_codes,            array: true, default: []
      t.decimal :base_rate,            null: false, precision: 8, scale: 2, default: 0
      t.decimal :per_item_fee,         null: false, precision: 8, scale: 2, default: 0
      t.decimal :large_item_surcharge, null: false, precision: 8, scale: 2, default: 0
      t.boolean :active,               default: true

      t.timestamps
    end

    add_index :delivery_zones, :zip_codes, using: :gin
    add_index :delivery_zones, :active
  end
end
