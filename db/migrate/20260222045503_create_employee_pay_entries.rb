class CreateEmployeePayEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :employee_pay_entries do |t|
      t.decimal    :amount,        precision: 10, scale: 2, null: false
      t.string     :employee_name, null: false
      t.text       :description
      t.date       :paid_on,       null: false
      t.references :created_by,    null: true, foreign_key: { to_table: :users }
      t.timestamps
    end

    add_index :employee_pay_entries, :paid_on
  end
end
