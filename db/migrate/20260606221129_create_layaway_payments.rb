class CreateLayawayPayments < ActiveRecord::Migration[8.0]
  def change
    create_table :layaway_payments do |t|
      t.references :order,        null: false, foreign_key: true
      t.decimal    :amount,       precision: 10, scale: 2, null: false
      t.text       :note
      t.bigint     :collected_by_id, null: false
      t.datetime   :paid_at,      null: false
      t.timestamps
    end

    add_foreign_key :layaway_payments, :users, column: :collected_by_id
    add_index :layaway_payments, :collected_by_id
  end
end
