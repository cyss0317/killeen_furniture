# This file is idempotent — safe to run multiple times.
puts "Seeding database..."

# === Global Settings ===
[
  ["global_markup_percentage", "35.0"],
  ["tax_rate",                 "0.0"],
  ["admin_notification_email", "admin@killeenfurniture.com"]
].each do |key, value|
  GlobalSetting.find_or_create_by!(key: key) { |s| s.value = value }
end
puts "  ✓ Global settings"

# === Super Admin User ===
admin = User.find_or_initialize_by(email: "admin@killeenfurniture.com")
unless admin.persisted?
  admin.assign_attributes(
    first_name: "Store",
    last_name:  "Admin",
    password:   "changeme123!",
    role:       :super_admin
  )
  admin.save!
  puts "  ✓ Super admin created (admin@killeenfurniture.com / changeme123!)"
else
  admin.update!(role: :super_admin) unless admin.super_admin?
  puts "  ✓ Super admin already exists"
end

# === Delivery Zones ===
unless DeliveryZone.exists?
  DeliveryZone.create!([
    {
      name:                 "Zone A – Killeen Local",
      zip_codes:            %w[76541 76542 76543 76544 76548 76549],
      base_rate:            75.00,
      per_item_fee:         10.00,
      large_item_surcharge: 25.00,
      active:               true
    },
    {
      name:                 "Zone B – Fort Hood / Copperas Cove",
      zip_codes:            %w[76544 76545 76522 76523],
      base_rate:            95.00,
      per_item_fee:         12.00,
      large_item_surcharge: 30.00,
      active:               true
    },
    {
      name:                 "Zone C – Harker Heights / Nolanville",
      zip_codes:            %w[76548 76559],
      base_rate:            85.00,
      per_item_fee:         10.00,
      large_item_surcharge: 25.00,
      active:               true
    },
    {
      name:                 "Zone D – Waco Area (Extended)",
      zip_codes:            %w[76701 76702 76703 76704 76705 76706 76707 76708 76710 76711 76712],
      base_rate:            150.00,
      per_item_fee:         20.00,
      large_item_surcharge: 50.00,
      active:               true
    }
  ])
  puts "  ✓ Delivery zones created"
end

# === Categories ===
unless Category.exists?
  living_room = Category.create!(name: "Living Room", position: 1)
  Category.create!([
    { name: "Sofas & Sectionals", parent: living_room, position: 1 },
    { name: "Coffee Tables",      parent: living_room, position: 2 },
    { name: "TV Stands & Media",  parent: living_room, position: 3 },
    { name: "Accent Chairs",      parent: living_room, position: 4 },
    { name: "Ottomans",           parent: living_room, position: 5 }
  ])

  bedroom = Category.create!(name: "Bedroom", position: 2)
  Category.create!([
    { name: "Beds & Headboards",  parent: bedroom, position: 1 },
    { name: "Dressers & Chests",  parent: bedroom, position: 2 },
    { name: "Nightstands",        parent: bedroom, position: 3 },
    { name: "Bedroom Sets",       parent: bedroom, position: 4 }
  ])

  dining = Category.create!(name: "Dining Room", position: 3)
  Category.create!([
    { name: "Dining Sets",        parent: dining, position: 1 },
    { name: "Dining Tables",      parent: dining, position: 2 },
    { name: "Dining Chairs",      parent: dining, position: 3 },
    { name: "Buffets & Sideboards", parent: dining, position: 4 }
  ])

  office = Category.create!(name: "Home Office", position: 4)
  Category.create!([
    { name: "Desks",              parent: office, position: 1 },
    { name: "Office Chairs",      parent: office, position: 2 },
    { name: "Bookcases",          parent: office, position: 3 }
  ])

  Category.create!(name: "Outdoor", position: 5)
  Category.create!(name: "Mattresses", position: 6)

  puts "  ✓ Categories created"
end

# === Sample Products (for development) ===
if Rails.env.development? && Product.count < 5
  sofas = Category.find_by(name: "Sofas & Sectionals")
  beds  = Category.find_by(name: "Beds & Headboards")

  if sofas && beds
    Product.create!([
      {
        name:              "Darcy Sofa",
        brand:             "Ashley Furniture",
        sku:               "AF-3840138",
        category:          sofas,
        short_description: "Classic loveseat sofa in java brown microfiber with plush cushions.",
        base_cost:         320.00,
        markup_percentage: 35.0,
        stock_quantity:    4,
        status:            :published,
        featured:          true,
        weight:            105.0,
        color:             "Java",
        material:          "Microfiber"
      },
      {
        name:              "Maier Queen Bed",
        brand:             "Ashley Furniture",
        sku:               "AF-B680-54",
        category:          beds,
        short_description: "Contemporary upholstered queen bed with button tufting in charcoal.",
        base_cost:         440.00,
        markup_percentage: 35.0,
        stock_quantity:    2,
        status:            :published,
        featured:          true,
        weight:            88.0,
        color:             "Charcoal",
        material:          "Polyester"
      }
    ])
    puts "  ✓ Sample products created"
  end
end

puts "\nSeeding complete!"
