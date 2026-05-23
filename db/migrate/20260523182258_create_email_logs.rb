class CreateEmailLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :email_logs do |t|
      t.references :order,  null: true,  foreign_key: true, index: true
      t.string     :to,     null: false
      t.string     :subject, null: false
      t.string     :action_name
      t.datetime   :sent_at, null: false

      t.timestamps
    end

    add_index :email_logs, :sent_at
  end
end
