class AddAdminKindToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :admin_kind, :integer, default: nil
  end
end
