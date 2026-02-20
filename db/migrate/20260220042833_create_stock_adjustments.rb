class CreateStockAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :stock_adjustments do |t|
      t.references :product,    null: false, foreign_key: true
      t.integer    :quantity_change, null: false
      t.string     :reason,     null: false
      t.references :admin_user, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :stock_adjustments, :created_at
  end
end
