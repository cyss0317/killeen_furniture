class CreateGlobalSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :global_settings do |t|
      t.string :key,   null: false
      t.string :value

      t.timestamps
    end

    add_index :global_settings, :key, unique: true
  end
end
