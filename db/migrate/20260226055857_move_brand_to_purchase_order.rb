class MoveBrandToPurchaseOrder < ActiveRecord::Migration[8.0]
  def up
    add_column :purchase_orders, :brand, :string unless column_expert?(:purchase_orders, :brand)
  end

  def down
    remove_column :purchase_orders, :brand if column_exists?(:purchase_orders, :brand)
  end

  private

  def column_expert?(table, column)
    column_exists?(table, column)
  end
end
