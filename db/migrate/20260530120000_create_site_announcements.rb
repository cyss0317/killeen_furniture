class CreateSiteAnnouncements < ActiveRecord::Migration[8.0]
  def change
    create_table :site_announcements do |t|
      t.text     :message,   null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at,   null: false
      t.boolean  :active,    null: false, default: true

      t.timestamps
    end
  end
end
