class AddEmployeeFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :pay_type, :integer
    add_column :users, :pay_rate, :decimal, precision: 10, scale: 2
  end
end
