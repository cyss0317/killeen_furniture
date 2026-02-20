class AddQrTokenToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :qr_token, :string
    add_index  :products, :qr_token, unique: true
  end
end
