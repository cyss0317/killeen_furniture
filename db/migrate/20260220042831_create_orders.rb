class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string     :order_number,               null: false
      t.references :user,                       null: true, foreign_key: true
      t.string     :guest_email
      t.string     :guest_name
      t.string     :guest_phone
      t.integer    :status,                     null: false, default: 0
      t.jsonb      :shipping_address,           null: false, default: {}
      t.decimal    :subtotal,                   null: false, precision: 10, scale: 2, default: 0
      t.decimal    :tax_amount,                 null: false, precision: 10, scale: 2, default: 0
      t.decimal    :shipping_amount,            null: false, precision: 10, scale: 2, default: 0
      t.decimal    :grand_total,                null: false, precision: 10, scale: 2, default: 0
      t.string     :stripe_payment_intent_id
      t.references :delivery_zone,              null: true, foreign_key: true
      t.text       :notes

      t.timestamps
    end

    add_index :orders, :order_number,              unique: true
    add_index :orders, :status
    add_index :orders, :stripe_payment_intent_id,  unique: true
    add_index :orders, :guest_email
    add_index :orders, :created_at
  end
end
