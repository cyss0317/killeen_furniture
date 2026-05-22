class FixDiningCategoryParents < ActiveRecord::Migration[8.0]
  def up
    dining_room = Category.find_by(name: "Dining Room")
    return unless dining_room

    Category.where(name: ["Dining Set", "Table"], parent_id: nil)
            .update_all(parent_id: dining_room.id)
  end

  def down
    Category.where(name: ["Dining Set", "Table"], parent_id: Category.find_by(name: "Dining Room")&.id)
            .update_all(parent_id: nil)
  end
end
