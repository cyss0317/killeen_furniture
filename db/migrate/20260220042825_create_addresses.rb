class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: true, foreign_key: true
      t.string :full_name,      null: false
      t.string :street_address, null: false
      t.string :city,           null: false
      t.string :state,          null: false
      t.string :zip_code,       null: false
      t.boolean :is_default,    default: false, null: false

      t.timestamps
    end

    add_index :addresses, [:user_id, :is_default]
  end
end
