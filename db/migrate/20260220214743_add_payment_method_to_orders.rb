class AddPaymentMethodToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :payment_method, :integer, default: 0, null: false
    add_column :orders, :external_payment_reference, :text
  end
end
