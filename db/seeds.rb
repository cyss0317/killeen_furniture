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

# === Ashley Furniture Product Catalog ===
load Rails.root.join("db/seeds/ashley_products.rb")

puts "\nSeeding complete!"

# === Delivery Admin User ===
delivery_user = User.find_or_initialize_by(email: "delivery@killeenfurniture.com")
unless delivery_user.persisted?
  delivery_user.assign_attributes(
    first_name: "Delivery",
    last_name:  "Driver",
    password:   "changeme123!",
    role:       :admin,
    admin_kind: :delivery
  )
  delivery_user.save!
  puts "  ✓ Delivery admin created (delivery@killeenfurniture.com / changeme123!)"
else
  delivery_user.update!(role: :admin, admin_kind: :delivery)
  puts "  ✓ Delivery admin already exists"
end

# === Backfill QR tokens for existing products ===
without_tokens = Product.where(qr_token: nil).count
if without_tokens > 0
  Product.where(qr_token: nil).find_each do |product|
    product.update_column(:qr_token, SecureRandom.urlsafe_base64(16))
  end
  puts "  ✓ QR tokens backfilled for #{without_tokens} products"
end

# === 30 Sample Orders (uses FactoryBot) ===
require "factory_bot_rails"
include FactoryBot::Syntax::Methods

if Order.count < 30
  # Get existing products and customers
  products = Product.published.to_a
  customers = User.where(role: :customer).to_a
  zone = DeliveryZone.first

  # Create some sample customers if none exist
  if customers.empty?
    5.times do |i|
      customers << User.create!(
        first_name: Faker::Name.first_name,
        last_name:  Faker::Name.last_name,
        email:      "customer#{i + 1}@example.com",
        password:   "password123!",
        role:       :customer
      )
    end
    puts "  ✓ Sample customers created"
  end

  def build_shipping_address(name)
    {
      "full_name"      => name,
      "street_address" => Faker::Address.street_address,
      "city"           => "Killeen",
      "state"          => "TX",
      "zip_code"       => ["76541", "76542", "76543"].sample
    }
  end

  def add_items_to_order(order, products)
    items = products.sample(rand(1..3))
    items.each do |product|
      qty = rand(1..2)
      order.order_items.create!(
        product:           product,
        quantity:          qty,
        unit_price:        product.selling_price,
        unit_cost:         product.base_cost,
        markup_percentage: product.markup_percentage,
        product_name:      product.name,
        product_sku:       product.sku
      )
    end
    subtotal = order.order_items.sum { |i| i.unit_price * i.quantity }
    order.update_columns(
      subtotal:    subtotal,
      grand_total: subtotal + order.shipping_amount + order.tax_amount
    )
  end

  # 10 orders: pending/assigned (future deliveries)
  10.times do |i|
    customer = customers.sample
    order = Order.create!(
      user:             customer,
      status:           :scheduled_for_delivery,
      source:           [:admin_manual, :phone, :web_customer].sample,
      shipping_address: build_shipping_address(customer.full_name),
      subtotal:         0,
      shipping_amount:  75.00,
      tax_amount:       0,
      grand_total:      75.00,
      delivery_zone:    zone,
      assigned_to:      delivery_user
    )
    add_items_to_order(order, products)
    order.delivery_events.create!(
      status:     :assigned,
      created_by: admin,
      note:       "Assigned to #{delivery_user.full_name}"
    )
  end

  # 10 orders: delivered
  10.times do |i|
    customer = customers.sample
    order = Order.create!(
      user:             customer,
      status:           :delivered,
      source:           :web_customer,
      shipping_address: build_shipping_address(customer.full_name),
      subtotal:         0,
      shipping_amount:  85.00,
      tax_amount:       0,
      grand_total:      85.00,
      delivery_zone:    zone,
      assigned_to:      delivery_user,
      delivered_by:     delivery_user,
      delivered_at:     Faker::Time.backward(days: 30, period: :day),
      created_at:       Faker::Time.backward(days: 45, period: :day)
    )
    add_items_to_order(order, products)
    order.delivery_events.create!(status: :assigned,   created_by: admin, note: "Assigned to #{delivery_user.full_name}")
    order.delivery_events.create!(status: :delivered,  created_by: delivery_user, note: "Delivered successfully")
  end

  # 10 orders: mixed statuses (paid, out_for_delivery, canceled, admin_manual)
  statuses = [:paid, :paid, :out_for_delivery, :out_for_delivery, :canceled,
              :paid, :scheduled_for_delivery, :paid, :out_for_delivery, :canceled]
  statuses.each do |status|
    customer = customers.sample
    assigned = status.in?(%i[out_for_delivery]) ? delivery_user : nil
    order = Order.create!(
      user:             customer,
      status:           status,
      source:           status == :paid ? :admin_manual : :web_customer,
      shipping_address: build_shipping_address(customer.full_name),
      subtotal:         0,
      shipping_amount:  95.00,
      tax_amount:       0,
      grand_total:      95.00,
      delivery_zone:    zone,
      assigned_to:      assigned
    )
    add_items_to_order(order, products)
    if assigned
      order.delivery_events.create!(status: :assigned, created_by: admin, note: "Assigned")
      order.delivery_events.create!(status: :out_for_delivery, created_by: delivery_user, note: "Out for delivery")
    end
  end

  puts "  ✓ 30 sample orders created"
end
