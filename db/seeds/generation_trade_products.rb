# Generation Trade Product Catalog Seed
# ~5 products per subcategory across key room categories
# Base costs reflect typical dealer/wholesale pricing; selling price auto-calculated via 35% markup.

puts "  Seeding Generation Trade product catalog..."

GT_BRAND = "Generation Trade"

def upsert_gt_product(attrs)
  product = Product.find_or_initialize_by(sku: attrs[:sku])
  product.assign_attributes(
    attrs.merge(
      brand:             GT_BRAND,
      status:            :published,
      markup_percentage: 35.0
    )
  )
  product.save!
end

# ============================================================
# LIVING ROOM — Sofas & Sectionals
# ============================================================
sofas = Category.find_by!(name: "Sofas & Sectionals")

[
  {
    sku: "GT-S1001", name: "Montclair Gray Sofa",
    short_description: "Contemporary low-profile sofa in silver-gray linen blend with solid wood legs.",
    base_cost: 520.00, stock_quantity: 5, weight: 120.0, color: "Gray", material: "Linen Blend",
    dimensions: { "width" => 84, "depth" => 36, "height" => 34 }
  },
  {
    sku: "GT-S1002", name: "Hudson Slate Sectional",
    short_description: "L-shaped sectional with reversible chaise in slate performance fabric. USB charging ports in armrest.",
    base_cost: 980.00, stock_quantity: 2, weight: 240.0, color: "Slate", material: "Performance Fabric",
    dimensions: { "width" => 118, "depth" => 90, "height" => 36 }
  },
  {
    sku: "GT-S1003", name: "Brentwood Navy Sofa",
    short_description: "Rolled-arm sofa in deep navy velvet with turned wood legs and tufted seat cushions.",
    base_cost: 610.00, stock_quantity: 3, weight: 135.0, color: "Navy", material: "Velvet",
    dimensions: { "width" => 86, "depth" => 37, "height" => 36 }
  },
  {
    sku: "GT-S1004", name: "Garrison Ivory Loveseat",
    short_description: "Compact loveseat in stain-resistant ivory fabric. Ideal for smaller living spaces.",
    base_cost: 380.00, stock_quantity: 6, weight: 88.0, color: "Ivory", material: "Fabric",
    dimensions: { "width" => 62, "depth" => 35, "height" => 35 }
  },
  {
    sku: "GT-S1005", name: "Palermo Taupe Sofa",
    short_description: "Mid-century inspired sofa with angled legs and button-tufted back in warm taupe.",
    base_cost: 545.00, stock_quantity: 4, weight: 115.0, color: "Taupe", material: "Fabric",
    dimensions: { "width" => 80, "depth" => 34, "height" => 33 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: sofas)) }

# ============================================================
# LIVING ROOM — Accent Chairs
# ============================================================
accent = Category.find_by!(name: "Accent Chairs")

[
  {
    sku: "GT-AC1001", name: "Cobalt Wing Chair",
    short_description: "Bold cobalt blue wing-back chair with contrast piping and solid walnut legs.",
    base_cost: 310.00, stock_quantity: 7, weight: 55.0, color: "Blue", material: "Fabric",
    dimensions: { "width" => 30, "depth" => 33, "height" => 42 }
  },
  {
    sku: "GT-AC1002", name: "Fern Cream Barrel Chair",
    short_description: "360° swivel barrel chair in cream bouclé fabric. Ideal for reading nooks.",
    base_cost: 355.00, stock_quantity: 4, weight: 48.0, color: "Ivory", material: "Bouclé",
    dimensions: { "width" => 32, "depth" => 32, "height" => 31 }
  },
  {
    sku: "GT-AC1003", name: "Saxon Charcoal Club Chair",
    short_description: "Deeply cushioned club chair in charcoal herringbone weave with brass nail-head trim.",
    base_cost: 395.00, stock_quantity: 3, weight: 62.0, color: "Charcoal", material: "Herringbone Fabric",
    dimensions: { "width" => 34, "depth" => 35, "height" => 34 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: accent)) }

# ============================================================
# LIVING ROOM — Coffee Tables
# ============================================================
coffee = Category.find_by!(name: "Coffee Tables")

[
  {
    sku: "GT-CT1001", name: "Arched Walnut Coffee Table",
    short_description: "Solid walnut coffee table with arched base and open shelf. Hand-oiled finish.",
    base_cost: 420.00, stock_quantity: 4, weight: 65.0, color: "Walnut", material: "Solid Walnut",
    dimensions: { "width" => 48, "depth" => 24, "height" => 18 }
  },
  {
    sku: "GT-CT1002", name: "Marble Top Oval Coffee Table",
    short_description: "White Carrara marble-top oval table with gold-toned metal base. Luxe contemporary styling.",
    base_cost: 560.00, stock_quantity: 2, weight: 78.0, color: "White", material: "Marble & Metal",
    dimensions: { "width" => 50, "depth" => 28, "height" => 17 }
  },
  {
    sku: "GT-CT1003", name: "Farmhouse Oak Coffee Table",
    short_description: "Reclaimed oak coffee table with X-cross base and lower shelf. Rustic-chic look.",
    base_cost: 310.00, stock_quantity: 6, weight: 70.0, color: "Oak", material: "Reclaimed Oak",
    dimensions: { "width" => 52, "depth" => 26, "height" => 19 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: coffee)) }

# ============================================================
# BEDROOM — Beds & Headboards
# ============================================================
beds = Category.find_by!(name: "Beds & Headboards")

[
  {
    sku: "GT-BD1001", name: "Ashford Upholstered Queen Bed",
    short_description: "Queen platform bed with padded channel-stitch headboard in warm beige linen.",
    base_cost: 680.00, stock_quantity: 3, weight: 140.0, color: "Beige", material: "Linen & Wood",
    dimensions: { "width" => 65, "depth" => 88, "height" => 54 }
  },
  {
    sku: "GT-BD1002", name: "Marquette Dark Walnut King Bed",
    short_description: "King platform bed in dark walnut with low-profile headboard and hidden USB nightstands.",
    base_cost: 880.00, stock_quantity: 2, weight: 180.0, color: "Dark Brown", material: "Walnut Veneer",
    dimensions: { "width" => 81, "depth" => 90, "height" => 48 }
  },
  {
    sku: "GT-BD1003", name: "Serena White Full Bed",
    short_description: "Full-size bed in crisp white with arched headboard and footboard. Clean Shaker styling.",
    base_cost: 510.00, stock_quantity: 4, weight: 120.0, color: "White", material: "MDF & Wood",
    dimensions: { "width" => 58, "depth" => 84, "height" => 50 }
  },
  {
    sku: "GT-BD1004", name: "Sutton Gray Velvet Queen Headboard",
    short_description: "Freestanding queen headboard in stone-gray velvet with nailhead border. Floor-to-ceiling silhouette.",
    base_cost: 320.00, stock_quantity: 5, weight: 45.0, color: "Gray", material: "Velvet",
    dimensions: { "width" => 64, "depth" => 4, "height" => 60 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: beds)) }

# ============================================================
# BEDROOM — Dressers & Chests
# ============================================================
dressers = Category.find_by!(name: "Dressers & Chests")

[
  {
    sku: "GT-DR1001", name: "Ridgeline 6-Drawer Dresser",
    short_description: "Six-drawer dresser in natural oak finish with brushed nickel pulls. Full extension drawers.",
    base_cost: 490.00, stock_quantity: 3, weight: 110.0, color: "Oak", material: "Oak Veneer",
    dimensions: { "width" => 58, "depth" => 17, "height" => 34 }
  },
  {
    sku: "GT-DR1002", name: "Clearwater White 5-Drawer Chest",
    short_description: "Tall five-drawer chest in antique white with antiqued brass ring pulls. Dovetail joints.",
    base_cost: 420.00, stock_quantity: 4, weight: 90.0, color: "Antique White", material: "Solid Pine",
    dimensions: { "width" => 32, "depth" => 16, "height" => 50 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: dressers)) }

# ============================================================
# DINING ROOM — Dining Sets
# ============================================================
dining_sets = Category.find_by!(name: "Dining Sets")

[
  {
    sku: "GT-DS1001", name: "Harvest 5-Piece Dining Set",
    short_description: "Round pedestal table with 4 ladder-back chairs in warm brown finish. Seats 4 comfortably.",
    base_cost: 720.00, stock_quantity: 2, weight: 185.0, color: "Brown", material: "Solid Wood",
    dimensions: { "width" => 48, "depth" => 48, "height" => 30 }
  },
  {
    sku: "GT-DS1002", name: "Lakeview 7-Piece Dining Set",
    short_description: "Rectangular dining table with 6 upholstered parsons chairs in dark espresso finish.",
    base_cost: 1100.00, stock_quantity: 1, weight: 280.0, color: "Espresso", material: "Acacia Wood",
    dimensions: { "width" => 72, "depth" => 38, "height" => 30 }
  },
  {
    sku: "GT-DS1003", name: "Nordic 5-Piece Counter-Height Set",
    short_description: "Modern counter-height table with 4 wishbone stools in natural ash. Perfect for kitchen dining.",
    base_cost: 580.00, stock_quantity: 3, weight: 150.0, color: "Natural", material: "Ash Wood",
    dimensions: { "width" => 50, "depth" => 32, "height" => 36 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: dining_sets)) }

# ============================================================
# HOME OFFICE — Desks
# ============================================================
desks = Category.find_by!(name: "Desks")

[
  {
    sku: "GT-DK1001", name: "Elara Walnut Writing Desk",
    short_description: "Mid-century writing desk in solid walnut with hairpin legs and single center drawer.",
    base_cost: 380.00, stock_quantity: 5, weight: 60.0, color: "Walnut", material: "Solid Walnut",
    dimensions: { "width" => 54, "depth" => 24, "height" => 30 }
  },
  {
    sku: "GT-DK1002", name: "Whitfield L-Shaped Desk",
    short_description: "Large L-shaped desk in white laminate with built-in cable management and keyboard tray.",
    base_cost: 450.00, stock_quantity: 3, weight: 88.0, color: "White", material: "Engineered Wood",
    dimensions: { "width" => 66, "depth" => 24, "height" => 30 }
  },
  {
    sku: "GT-DK1003", name: "Harlow Charcoal Standing Desk",
    short_description: "Electric height-adjustable desk in charcoal finish. Dual motor, memory presets, cable tray.",
    base_cost: 620.00, stock_quantity: 2, weight: 95.0, color: "Charcoal", material: "Steel & MDF",
    dimensions: { "width" => 60, "depth" => 24, "height" => 46 }
  }
].each { |attrs| upsert_gt_product(attrs.merge(category: desks)) }

puts "  ✓ Generation Trade product catalog seeded (#{Product.where(brand: GT_BRAND).count} products)"
