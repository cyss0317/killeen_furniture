class AddInvoiceDateToPurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :purchase_orders, :invoice_date, :date
  end
end
