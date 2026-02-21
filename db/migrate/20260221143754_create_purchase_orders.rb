class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.string   :reference_number, null: false
      t.integer  :status,           null: false, default: 0
      t.date     :ordered_at
      t.text     :notes
      t.references :created_by, null: true, foreign_key: { to_table: :users }

      t.timestamps
    end
    add_index :purchase_orders, :reference_number, unique: true
    add_index :purchase_orders, :status
  end
end
