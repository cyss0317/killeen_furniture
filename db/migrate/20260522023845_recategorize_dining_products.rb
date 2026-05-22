class RecategorizeDiningProducts < ActiveRecord::Migration[8.0]
  def up
    dining_room = Category.find_by(name: "Dining Room")
    return unless dining_room

    dining_ids = [dining_room.id] + dining_room.subcategories.pluck(:id)

    Product.where("name ILIKE ?", "%dining%")
           .where.not(category_id: dining_ids)
           .find_each do |product|
             target = if product.name.match?(/chair/i)
                        Category.find_by(name: "Dining Chairs")
                      elsif product.name.match?(/table/i)
                        Category.find_by(name: "Dining Tables")
                      elsif product.name.match?(/set/i)
                        Category.find_by(name: "Dining Sets")
                      elsif product.name.match?(/buffet|sideboard/i)
                        Category.find_by(name: "Buffets & Sideboards")
                      else
                        Category.find_by(name: "Dining Room")
                      end
             product.update_columns(category_id: target.id) if target
           end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
