class AddUserAndHoursToEmployeePayEntries < ActiveRecord::Migration[8.0]
  def change
    add_reference :employee_pay_entries, :user, null: true, foreign_key: true
    add_column :employee_pay_entries, :hours_worked, :decimal, precision: 8, scale: 2
  end
end
