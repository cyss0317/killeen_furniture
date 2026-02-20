class CreateDeliveryEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :delivery_events do |t|
      t.references :order,      null: false, foreign_key: true
      t.integer    :status,     null: false, default: 0
      t.text       :note
      t.references :created_by, null: true,  foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :delivery_events, :status
  end
end
