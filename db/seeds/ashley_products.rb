# Ashley Furniture Product Catalog Seed
# ~10 products per subcategory across all 18 subcategories
# Base costs reflect typical dealer/wholesale pricing; selling price is auto-calculated via 35% markup.

puts "  Seeding Ashley Furniture product catalog..."

BRAND = "Ashley Furniture"

def upsert_product(attrs)
  product = Product.find_or_initialize_by(sku: attrs[:sku])
  product.assign_attributes(
    attrs.merge(
      brand:             BRAND,
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
    sku: "AF-7650138",  name: "Darcy Sofa",
    short_description: "Casual microfiber sofa with pillowy armrests and reversible seat cushions. Available in Java and Cobblestone.",
    base_cost: 318.00, stock_quantity: 6, weight: 105.0, color: "Java", material: "Microfiber",
    dimensions: { "width" => 82, "depth" => 37, "height" => 38 }
  },
  {
    sku: "AF-1870218",  name: "Alenya Charcoal Sofa",
    short_description: "Contemporary track-arm sofa with corner-blocked frame in stain-resistant fabric.",
    base_cost: 345.00, stock_quantity: 4, weight: 114.0, color: "Charcoal", material: "Fabric",
    dimensions: { "width" => 86, "depth" => 38, "height" => 39 }
  },
  {
    sku: "AF-2780281",  name: "Nolana Coral Sofa",
    short_description: "Vibrant contemporary sofa in a bold coral hue with loose back pillows and plush seating.",
    base_cost: 355.00, stock_quantity: 3, weight: 118.0, color: "Coral", material: "Polyester",
    dimensions: { "width" => 88, "depth" => 36, "height" => 35 }
  },
  {
    sku: "AF-5530481",  name: "Altari Alloy 2-Piece Sectional",
    short_description: "Contemporary 2-piece sectional with chaise in stain-resistant alloy fabric. Corner-blocked frame.",
    base_cost: 580.00, stock_quantity: 2, weight: 210.0, color: "Alloy", material: "Fabric",
    dimensions: { "width" => 116, "depth" => 86, "height" => 38 }
  },
  {
    sku: "AF-5040551",  name: "Abinger Natural 2-Piece Sectional",
    short_description: "Soft-toned 2-piece sectional with attached cushions and loose throw pillow in natural fabric.",
    base_cost: 495.00, stock_quantity: 3, weight: 198.0, color: "Natural", material: "Fabric",
    dimensions: { "width" => 114, "depth" => 83, "height" => 37 }
  },
  {
    sku: "AF-7760481",  name: "Savesto 5-Piece Sectional",
    short_description: "Large modular 5-piece sectional with chaise in charcoal. Pocket coil seating with foam-cushioned back.",
    base_cost: 975.00, stock_quantity: 1, weight: 385.0, color: "Charcoal", material: "Fabric",
    dimensions: { "width" => 166, "depth" => 116, "height" => 39 }
  },
  {
    sku: "AF-2040155",  name: "Malone Fog Sofa",
    short_description: "Performance fabric sofa with tight back and track arms in a calming fog finish.",
    base_cost: 375.00, stock_quantity: 5, weight: 110.0, color: "Fog", material: "Performance Fabric",
    dimensions: { "width" => 84, "depth" => 37, "height" => 37 }
  },
  {
    sku: "AF-5960418",  name: "Benchcraft Maier Sofa",
    short_description: "Traditional roll-arm sofa with nailhead trim in neutral beige. Kiln-dried hardwood frame.",
    base_cost: 420.00, stock_quantity: 4, weight: 122.0, color: "Beige", material: "Polyester Blend",
    dimensions: { "width" => 90, "depth" => 38, "height" => 40 }
  },
  {
    sku: "AF-7870238",  name: "Rannis Loveseat",
    short_description: "Compact loveseat with double-sided platform-style seating and welt cord detailing.",
    base_cost: 255.00, stock_quantity: 5, weight: 86.0, color: "Nickel", material: "Fabric",
    dimensions: { "width" => 64, "depth" => 36, "height" => 38 }
  },
  {
    sku: "AF-7260318",  name: "Betrillo Sofa",
    short_description: "Casual tailored sofa with box cushions and pad-over-chaise seating in cobblestone.",
    base_cost: 295.00, stock_quantity: 6, weight: 98.0, color: "Cobblestone", material: "Microfiber",
    dimensions: { "width" => 80, "depth" => 37, "height" => 37 }
  }
].each { |attrs| upsert_product(attrs.merge(category: sofas, featured: false)) }

# ============================================================
# LIVING ROOM — Coffee Tables
# ============================================================
coffee = Category.find_by!(name: "Coffee Tables")

[
  {
    sku: "AF-T736-1",   name: "Wesling Rectangular Cocktail Table",
    short_description: "Rustic brown cocktail table with planked top and metal base details.",
    base_cost: 148.00, stock_quantity: 8, weight: 44.0, color: "Rustic Brown", material: "Wood/Metal",
    dimensions: { "width" => 48, "depth" => 26, "height" => 18 }
  },
  {
    sku: "AF-T788-1",   name: "Trinell Rectangular Cocktail Table",
    short_description: "Warm brown finish cocktail table with industrial metal pipe-style legs.",
    base_cost: 162.00, stock_quantity: 7, weight: 52.0, color: "Brown", material: "Wood Veneer",
    dimensions: { "width" => 50, "depth" => 26, "height" => 18 }
  },
  {
    sku: "AF-T092-1",   name: "Bolanburg Lift-Top Cocktail Table",
    short_description: "Antique white and brown two-tone lift-top coffee table with hidden storage.",
    base_cost: 188.00, stock_quantity: 6, weight: 58.0, color: "Antique White/Brown", material: "Wood",
    dimensions: { "width" => 50, "depth" => 28, "height" => 18 }
  },
  {
    sku: "AF-T500-1",   name: "Rockpoint Cocktail Table",
    short_description: "Warm brown contemporary cocktail table with lower display shelf.",
    base_cost: 135.00, stock_quantity: 9, weight: 40.0, color: "Warm Brown", material: "Wood",
    dimensions: { "width" => 47, "depth" => 26, "height" => 18 }
  },
  {
    sku: "AF-T417-1",   name: "Kettleby Lift-Top Cocktail Table",
    short_description: "Grayish brown cocktail table with lift-top and spacious interior storage.",
    base_cost: 195.00, stock_quantity: 5, weight: 62.0, color: "Grayish Brown", material: "Wood",
    dimensions: { "width" => 49, "depth" => 27, "height" => 18 }
  },
  {
    sku: "AF-T745-1",   name: "Roybeck Cocktail Table",
    short_description: "Contemporary warm brown coffee table with lower shelf and metal accents.",
    base_cost: 155.00, stock_quantity: 7, weight: 47.0, color: "Burnished Brown", material: "Wood/Metal",
    dimensions: { "width" => 48, "depth" => 26, "height" => 17 }
  },
  {
    sku: "AF-T553-1",   name: "Larimer Rectangular Cocktail Table",
    short_description: "Two-tone finish cocktail table with textured gray top and natural brown legs.",
    base_cost: 142.00, stock_quantity: 8, weight: 42.0, color: "Two-Tone Gray/Brown", material: "Wood",
    dimensions: { "width" => 48, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-T742-1",   name: "Haddigan Dark Brown Cocktail Table",
    short_description: "Casual dark brown cocktail table with plank-style top and stretcher shelf.",
    base_cost: 128.00, stock_quantity: 10, weight: 38.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 50, "depth" => 26, "height" => 18 }
  },
  {
    sku: "AF-T168-1",   name: "Ellbury Cocktail Table",
    short_description: "Medium brown cocktail table with carved decorative apron and tapered legs.",
    base_cost: 168.00, stock_quantity: 6, weight: 50.0, color: "Medium Brown", material: "Solid Wood",
    dimensions: { "width" => 48, "depth" => 26, "height" => 19 }
  },
  {
    sku: "AF-T822-1",   name: "Garletti Cocktail Table",
    short_description: "Dark charcoal cocktail table with lower shelf and angular metal base.",
    base_cost: 145.00, stock_quantity: 7, weight: 44.0, color: "Dark Charcoal", material: "Wood/Metal",
    dimensions: { "width" => 46, "depth" => 24, "height" => 18 }
  }
].each { |attrs| upsert_product(attrs.merge(category: coffee)) }

# ============================================================
# LIVING ROOM — TV Stands & Media
# ============================================================
tvstands = Category.find_by!(name: "TV Stands & Media")

[
  {
    sku: "AF-W267-68",  name: "Trinell Large TV Stand",
    short_description: "Warm brown TV stand with pipe-style legs and adjustable shelves. Fits TVs up to 70\".",
    base_cost: 245.00, stock_quantity: 5, weight: 88.0, color: "Brown", material: "Wood Veneer",
    dimensions: { "width" => 68, "depth" => 16, "height" => 30 }
  },
  {
    sku: "AF-W647-68",  name: "Bolanburg TV Stand",
    short_description: "Antique white two-tone TV stand with two glass doors and two drawers.",
    base_cost: 285.00, stock_quantity: 4, weight: 110.0, color: "Antique White/Brown", material: "Wood",
    dimensions: { "width" => 72, "depth" => 18, "height" => 32 }
  },
  {
    sku: "AF-W235-68",  name: "Budmore Large TV Stand",
    short_description: "Contemporary dark brown TV stand with open shelving and clean lines. Fits TVs up to 70\".",
    base_cost: 198.00, stock_quantity: 6, weight: 76.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 68, "depth" => 16, "height" => 28 }
  },
  {
    sku: "AF-W100-68",  name: "Rollynx TV Stand",
    short_description: "White and dark brown TV stand with open shelves and adjustable levelers.",
    base_cost: 175.00, stock_quantity: 7, weight: 65.0, color: "White/Dark Brown", material: "Engineered Wood",
    dimensions: { "width" => 68, "depth" => 15, "height" => 27 }
  },
  {
    sku: "AF-W160-68",  name: "Realyn Large TV Stand",
    short_description: "Chipped white cottage-style TV stand with three drawers and open shelves.",
    base_cost: 268.00, stock_quantity: 4, weight: 95.0, color: "Chipped White", material: "Wood",
    dimensions: { "width" => 74, "depth" => 18, "height" => 32 }
  },
  {
    sku: "AF-W215-68",  name: "Neilsville TV Stand",
    short_description: "White and light brown two-tone TV stand with wire management and open shelves.",
    base_cost: 185.00, stock_quantity: 6, weight: 70.0, color: "White/Light Brown", material: "Wood",
    dimensions: { "width" => 60, "depth" => 15, "height" => 28 }
  },
  {
    sku: "AF-W536-68",  name: "Jakmore Extra Large TV Stand",
    short_description: "Dark charcoal extra-wide TV stand with two cabinets and open center shelves. Fits TVs up to 80\".",
    base_cost: 318.00, stock_quantity: 3, weight: 125.0, color: "Dark Charcoal", material: "Wood/Metal",
    dimensions: { "width" => 80, "depth" => 18, "height" => 30 }
  },
  {
    sku: "AF-W485-68",  name: "Camiburg Warm Brown TV Stand",
    short_description: "Warm brown TV stand with adjustable shelves and cord management access.",
    base_cost: 225.00, stock_quantity: 5, weight: 80.0, color: "Warm Brown", material: "Wood",
    dimensions: { "width" => 70, "depth" => 17, "height" => 30 }
  },
  {
    sku: "AF-W357-68",  name: "Hamled TV Stand",
    short_description: "Dark brown TV stand with lower open shelf and two side cabinets with wood panel doors.",
    base_cost: 210.00, stock_quantity: 5, weight: 78.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 66, "depth" => 17, "height" => 29 }
  },
  {
    sku: "AF-W464-68",  name: "Dorrinson TV Stand",
    short_description: "Two-tone black and gray TV stand with smooth metal-look finish and open lower shelf.",
    base_cost: 192.00, stock_quantity: 6, weight: 72.0, color: "Black/Gray", material: "Engineered Wood",
    dimensions: { "width" => 64, "depth" => 16, "height" => 28 }
  }
].each { |attrs| upsert_product(attrs.merge(category: tvstands)) }

# ============================================================
# LIVING ROOM — Accent Chairs
# ============================================================
accent_chairs = Category.find_by!(name: "Accent Chairs")

[
  {
    sku: "AF-1310220",  name: "Cashonly Accent Chair",
    short_description: "Polyester accent chair with flared arms and button-tufted back. Ideal for bedroom or living room.",
    base_cost: 188.00, stock_quantity: 7, weight: 40.0, color: "Bone White", material: "Polyester",
    dimensions: { "width" => 31, "depth" => 32, "height" => 35 }
  },
  {
    sku: "AF-1640120",  name: "Annora Accent Chair",
    short_description: "Plush barrel accent chair with tight back and tapered wooden legs in alabaster.",
    base_cost: 215.00, stock_quantity: 5, weight: 42.0, color: "Alabaster", material: "Fabric",
    dimensions: { "width" => 33, "depth" => 33, "height" => 34 }
  },
  {
    sku: "AF-8390220",  name: "Deerpark Accent Chair",
    short_description: "Gray linen accent chair with flared arms and turned wooden legs. A classic statement piece.",
    base_cost: 235.00, stock_quantity: 4, weight: 44.0, color: "Gray", material: "Linen",
    dimensions: { "width" => 33, "depth" => 34, "height" => 36 }
  },
  {
    sku: "AF-1330120",  name: "Parlayne Accent Chair",
    short_description: "Contemporary accent chair with geometric-pattern fabric and natural wood frame.",
    base_cost: 248.00, stock_quantity: 4, weight: 45.0, color: "Multi-color", material: "Fabric",
    dimensions: { "width" => 32, "depth" => 33, "height" => 35 }
  },
  {
    sku: "AF-A3000020",  name: "Berneen Fog Accent Chair",
    short_description: "Ultra-soft fog performance fabric accent chair with tight back and wide seat.",
    base_cost: 268.00, stock_quantity: 4, weight: 46.0, color: "Fog", material: "Performance Fabric",
    dimensions: { "width" => 35, "depth" => 35, "height" => 33 }
  },
  {
    sku: "AF-8490302",  name: "Kellway Bisque Accent Chair",
    short_description: "Bisque-colored accent chair with track arms, a low sloping back, and solid wood legs.",
    base_cost: 195.00, stock_quantity: 6, weight: 38.0, color: "Bisque", material: "Polyester",
    dimensions: { "width" => 32, "depth" => 30, "height" => 33 }
  },
  {
    sku: "AF-A3000044",  name: "Yandel Slate Accent Chair",
    short_description: "Mid-century inspired accent chair in slate with tapered wood legs and button tufting.",
    base_cost: 278.00, stock_quantity: 4, weight: 47.0, color: "Slate", material: "Polyester",
    dimensions: { "width" => 33, "depth" => 33, "height" => 34 }
  },
  {
    sku: "AF-5160420",  name: "Theron Stone Accent Chair",
    short_description: "Contemporary accent chair in stone-gray with box seat cushion and track arms.",
    base_cost: 205.00, stock_quantity: 5, weight: 41.0, color: "Stone Gray", material: "Fabric",
    dimensions: { "width" => 31, "depth" => 32, "height" => 34 }
  },
  {
    sku: "AF-1490320",  name: "Arrowmask Accent Chair",
    short_description: "Classic rolled-arm accent chair with two-tone brindle fabric and solid wood legs.",
    base_cost: 222.00, stock_quantity: 5, weight: 43.0, color: "Two-Tone Brindle", material: "Fabric",
    dimensions: { "width" => 32, "depth" => 33, "height" => 35 }
  },
  {
    sku: "AF-1590302",  name: "Lyncott Charcoal/Chrome Accent Chair",
    short_description: "Geometric metal-base accent chair with charcoal fabric seat and chrome-finish legs.",
    base_cost: 245.00, stock_quantity: 4, weight: 35.0, color: "Charcoal/Chrome", material: "Fabric",
    dimensions: { "width" => 29, "depth" => 28, "height" => 32 }
  }
].each { |attrs| upsert_product(attrs.merge(category: accent_chairs)) }

# ============================================================
# LIVING ROOM — Ottomans
# ============================================================
ottomans = Category.find_by!(name: "Ottomans")

[
  {
    sku: "AF-7650308",  name: "Darcy Ottoman",
    short_description: "Matching ottoman for the Darcy collection. Java microfiber upholstery with flared feet.",
    base_cost: 88.00, stock_quantity: 8, weight: 28.0, color: "Java", material: "Microfiber",
    dimensions: { "width" => 38, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-5160408",  name: "Theron Stone Ottoman",
    short_description: "Coordinating stone-gray ottoman with box cushion and clean track base.",
    base_cost: 95.00, stock_quantity: 7, weight: 22.0, color: "Stone Gray", material: "Fabric",
    dimensions: { "width" => 40, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-1870208",  name: "Alenya Quartz Ottoman",
    short_description: "Corner-blocked ottoman with quartz fabric top and solid wooden feet.",
    base_cost: 105.00, stock_quantity: 7, weight: 24.0, color: "Quartz", material: "Fabric",
    dimensions: { "width" => 38, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-8490308",  name: "Kellway Bisque Ottoman",
    short_description: "Matching bisque ottoman with plush top cushion and solid wood legs.",
    base_cost: 92.00, stock_quantity: 8, weight: 21.0, color: "Bisque", material: "Polyester",
    dimensions: { "width" => 36, "depth" => 22, "height" => 18 }
  },
  {
    sku: "AF-1340608",  name: "Cashton Storage Ottoman",
    short_description: "Large tufted storage ottoman with hinged lid and espresso faux leather.",
    base_cost: 128.00, stock_quantity: 6, weight: 32.0, color: "Espresso", material: "Faux Leather",
    dimensions: { "width" => 45, "depth" => 25, "height" => 18 }
  },
  {
    sku: "AF-7260308",  name: "Bladen Coffee Ottoman",
    short_description: "Coffee-colored fabric ottoman with pillow-top surface and block feet.",
    base_cost: 98.00, stock_quantity: 8, weight: 22.0, color: "Coffee", material: "Fabric",
    dimensions: { "width" => 38, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-2780008",  name: "Janesley Cobblestone Ottoman",
    short_description: "Casual cobblestone microfiber ottoman with flared feet and box cushion.",
    base_cost: 85.00, stock_quantity: 9, weight: 20.0, color: "Cobblestone", material: "Microfiber",
    dimensions: { "width" => 36, "depth" => 22, "height" => 17 }
  },
  {
    sku: "AF-4970808",  name: "Mcdade Smoke Ottoman",
    short_description: "Large rectangular ottoman in smoke gray with tufted top and dark wood feet.",
    base_cost: 115.00, stock_quantity: 6, weight: 26.0, color: "Smoke", material: "Fabric",
    dimensions: { "width" => 44, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-1430308",  name: "Abalone Bone Ottoman",
    short_description: "Bone white fabric cocktail ottoman with decorative bun feet.",
    base_cost: 102.00, stock_quantity: 7, weight: 23.0, color: "Bone White", material: "Polyester",
    dimensions: { "width" => 40, "depth" => 24, "height" => 18 }
  },
  {
    sku: "AF-6510108",  name: "Darwyn Taupe Ottoman",
    short_description: "Round tufted ottoman in taupe with metal caster feet for easy repositioning.",
    base_cost: 122.00, stock_quantity: 6, weight: 25.0, color: "Taupe", material: "Fabric",
    dimensions: { "width" => 30, "depth" => 30, "height" => 18 }
  }
].each { |attrs| upsert_product(attrs.merge(category: ottomans)) }

# ============================================================
# BEDROOM — Beds & Headboards
# ============================================================
beds = Category.find_by!(name: "Beds & Headboards")

[
  {
    sku: "AF-B680-54",  name: "Maier Charcoal Queen Bed",
    short_description: "Contemporary upholstered queen bed with button tufting and solid wood feet in charcoal.",
    base_cost: 440.00, stock_quantity: 3, weight: 88.0, color: "Charcoal", material: "Polyester",
    dimensions: { "width" => 65, "depth" => 87, "height" => 54 }, featured: true
  },
  {
    sku: "AF-B192-57",  name: "Cambeck Queen Panel Bed",
    short_description: "Warm brown queen panel bed with dressy wire brushed texture and storage footboard drawers.",
    base_cost: 485.00, stock_quantity: 3, weight: 112.0, color: "Warm Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 90, "height" => 57 }
  },
  {
    sku: "AF-B446-57",  name: "Trinell Queen Panel Bed",
    short_description: "Rustic brown queen panel bed with pipe-style legs and planked details.",
    base_cost: 395.00, stock_quantity: 4, weight: 98.0, color: "Brown", material: "Wood Veneer",
    dimensions: { "width" => 65, "depth" => 88, "height" => 57 }
  },
  {
    sku: "AF-B743-57",  name: "Realyn Queen Sleigh Bed",
    short_description: "Chipped white cottage-style queen sleigh bed with ornate scrolled headboard.",
    base_cost: 525.00, stock_quantity: 2, weight: 125.0, color: "Chipped White", material: "Wood",
    dimensions: { "width" => 65, "depth" => 92, "height" => 62 }
  },
  {
    sku: "AF-B405-57",  name: "Olivet Queen Upholstered Bed",
    short_description: "Soft gray upholstered queen bed with nailhead border and low-profile footboard.",
    base_cost: 418.00, stock_quantity: 3, weight: 90.0, color: "Gray", material: "Faux Leather",
    dimensions: { "width" => 65, "depth" => 88, "height" => 52 }
  },
  {
    sku: "AF-B512-57",  name: "Alisdair Queen Panel Bed",
    short_description: "Dark brown traditional queen panel bed with decorative pilasters and carved details.",
    base_cost: 462.00, stock_quantity: 3, weight: 105.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 89, "height" => 60 }
  },
  {
    sku: "AF-B211-57",  name: "Neilsville White/Light Brown Queen Bed",
    short_description: "Two-tone white and light brown farmhouse-style queen bed with plank headboard.",
    base_cost: 378.00, stock_quantity: 4, weight: 92.0, color: "White/Light Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 87, "height" => 53 }
  },
  {
    sku: "AF-B594-57",  name: "Robbinsdale Antique White Queen Sleigh Bed",
    short_description: "Antique white queen sleigh bed with vintage-style hardware and curved headboard.",
    base_cost: 545.00, stock_quantity: 2, weight: 128.0, color: "Antique White", material: "Wood",
    dimensions: { "width" => 66, "depth" => 93, "height" => 64 }
  },
  {
    sku: "AF-B090-81",  name: "Dolante Queen Upholstered Bed",
    short_description: "King-size upholstered platform bed in beige with horizontal channel tufting.",
    base_cost: 488.00, stock_quantity: 3, weight: 108.0, color: "Beige", material: "Fabric",
    dimensions: { "width" => 65, "depth" => 88, "height" => 48 }
  },
  {
    sku: "AF-B100-57",  name: "Quinin Queen Upholstered Bed",
    short_description: "Charcoal velvet queen upholstered bed with wide shelter headboard and block feet.",
    base_cost: 465.00, stock_quantity: 3, weight: 95.0, color: "Charcoal", material: "Velvet",
    dimensions: { "width" => 65, "depth" => 87, "height" => 58 }
  }
].each { |attrs| upsert_product(attrs.merge(category: beds)) }

# ============================================================
# BEDROOM — Dressers & Chests
# ============================================================
dressers = Category.find_by!(name: "Dressers & Chests")

[
  {
    sku: "AF-B680-31",  name: "Maier Charcoal Dresser",
    short_description: "Seven-drawer dresser with upholstered top panel and chrome-color metal hardware.",
    base_cost: 378.00, stock_quantity: 4, weight: 128.0, color: "Charcoal", material: "Engineered Wood",
    dimensions: { "width" => 56, "depth" => 15, "height" => 38 }
  },
  {
    sku: "AF-B192-31",  name: "Cambeck Warm Brown Dresser",
    short_description: "Six-drawer dresser with wire-brushed warm brown finish and decorative hardware.",
    base_cost: 398.00, stock_quantity: 3, weight: 142.0, color: "Warm Brown", material: "Wood",
    dimensions: { "width" => 62, "depth" => 16, "height" => 36 }
  },
  {
    sku: "AF-B446-31",  name: "Trinell Brown Dresser",
    short_description: "Six-drawer dresser with warm brown finish, pipe-style accents, and smooth glides.",
    base_cost: 348.00, stock_quantity: 4, weight: 135.0, color: "Brown", material: "Wood Veneer",
    dimensions: { "width" => 58, "depth" => 15, "height" => 36 }
  },
  {
    sku: "AF-B743-31",  name: "Realyn Chipped White Dresser",
    short_description: "Six-drawer cottage dresser with chipped white finish and antique brass hardware.",
    base_cost: 418.00, stock_quantity: 3, weight: 148.0, color: "Chipped White", material: "Wood",
    dimensions: { "width" => 62, "depth" => 17, "height" => 38 }
  },
  {
    sku: "AF-B092-31",  name: "Bolanburg Antique White Dresser",
    short_description: "Eight-drawer dresser in antique white with brown top and brushed nickel hardware.",
    base_cost: 425.00, stock_quantity: 3, weight: 155.0, color: "Antique White/Brown", material: "Wood",
    dimensions: { "width" => 66, "depth" => 17, "height" => 38 }
  },
  {
    sku: "AF-B512-31",  name: "Alisdair Dark Brown Dresser",
    short_description: "Six-drawer traditional dresser with dark brown finish and round decorative hardware.",
    base_cost: 385.00, stock_quantity: 3, weight: 140.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 60, "depth" => 16, "height" => 37 }
  },
  {
    sku: "AF-B211-31",  name: "Neilsville Chest of Drawers",
    short_description: "Five-drawer chest in white and light brown with cedar-lined bottom drawer.",
    base_cost: 295.00, stock_quantity: 5, weight: 112.0, color: "White/Light Brown", material: "Wood",
    dimensions: { "width" => 30, "depth" => 15, "height" => 52 }
  },
  {
    sku: "AF-B594-31",  name: "Robbinsdale Antique White Dresser",
    short_description: "Eight-drawer vintage dresser in antique white with carved overlays and fancy hardware.",
    base_cost: 445.00, stock_quantity: 2, weight: 158.0, color: "Antique White", material: "Wood",
    dimensions: { "width" => 64, "depth" => 17, "height" => 38 }
  },
  {
    sku: "AF-B090-46",  name: "Dolante Beige Chest",
    short_description: "Five-drawer upholstered chest with fabric exterior and smooth cedar-lined drawers.",
    base_cost: 322.00, stock_quantity: 4, weight: 118.0, color: "Beige", material: "Fabric",
    dimensions: { "width" => 30, "depth" => 17, "height" => 54 }
  },
  {
    sku: "AF-B100-31",  name: "Quinin Charcoal Dresser",
    short_description: "Six-drawer dresser with upholstered side panels and brushed chrome hardware.",
    base_cost: 395.00, stock_quantity: 3, weight: 145.0, color: "Charcoal", material: "Engineered Wood",
    dimensions: { "width" => 60, "depth" => 16, "height" => 37 }
  }
].each { |attrs| upsert_product(attrs.merge(category: dressers)) }

# ============================================================
# BEDROOM — Nightstands
# ============================================================
nightstands = Category.find_by!(name: "Nightstands")

[
  { sku: "AF-B680-92",  name: "Maier Charcoal Nightstand",      short_description: "Two-drawer nightstand with upholstered top panel matching the Maier bedroom collection.",                base_cost: 148.00, stock_quantity: 8, weight: 38.0, color: "Charcoal",         material: "Engineered Wood", dimensions: { "width" => 24, "depth" => 16, "height" => 28 } },
  { sku: "AF-B192-91",  name: "Cambeck Warm Brown Nightstand",  short_description: "Two-drawer nightstand in warm brown wire-brushed finish to complement the Cambeck collection.",    base_cost: 158.00, stock_quantity: 7, weight: 42.0, color: "Warm Brown",        material: "Wood",            dimensions: { "width" => 25, "depth" => 16, "height" => 28 } },
  { sku: "AF-B446-92",  name: "Trinell Brown Nightstand",       short_description: "One-drawer nightstand with open shelf and warm brown finish in the Trinell collection.",             base_cost: 128.00, stock_quantity: 9, weight: 32.0, color: "Brown",             material: "Wood Veneer",     dimensions: { "width" => 22, "depth" => 16, "height" => 27 } },
  { sku: "AF-B743-92",  name: "Realyn Chipped White Nightstand",short_description: "Cottage-style two-drawer nightstand in chipped white with antique brass ring pulls.",               base_cost: 162.00, stock_quantity: 7, weight: 44.0, color: "Chipped White",    material: "Wood",            dimensions: { "width" => 27, "depth" => 17, "height" => 30 } },
  { sku: "AF-B092-92",  name: "Bolanburg Antique White Nightstand", short_description: "Three-drawer nightstand in antique white with brown tops and brushed nickel hardware.",         base_cost: 175.00, stock_quantity: 6, weight: 46.0, color: "Antique White/Brown", material: "Wood",           dimensions: { "width" => 28, "depth" => 17, "height" => 32 } },
  { sku: "AF-B512-92",  name: "Alisdair Dark Brown Nightstand", short_description: "Traditional two-drawer nightstand with dark brown finish and bun feet.",                             base_cost: 145.00, stock_quantity: 8, weight: 38.0, color: "Dark Brown",        material: "Wood",            dimensions: { "width" => 26, "depth" => 16, "height" => 28 } },
  { sku: "AF-B211-92",  name: "Neilsville White Nightstand",    short_description: "Two-drawer nightstand in white and light brown farmhouse styling.",                                  base_cost: 132.00, stock_quantity: 9, weight: 34.0, color: "White/Light Brown", material: "Wood",            dimensions: { "width" => 24, "depth" => 16, "height" => 27 } },
  { sku: "AF-B594-92",  name: "Robbinsdale Antique White Nightstand", short_description: "Antique white nightstand with decorative mirror front and shaped legs.",                      base_cost: 178.00, stock_quantity: 6, weight: 45.0, color: "Antique White",     material: "Wood",            dimensions: { "width" => 28, "depth" => 17, "height" => 32 } },
  { sku: "AF-B090-92",  name: "Dolante Beige Nightstand",       short_description: "One-drawer upholstered nightstand with open shelf and metal legs.",                                  base_cost: 138.00, stock_quantity: 8, weight: 32.0, color: "Beige",             material: "Fabric",          dimensions: { "width" => 22, "depth" => 16, "height" => 26 } },
  { sku: "AF-B100-91",  name: "Quinin Charcoal Nightstand",     short_description: "Two-drawer nightstand with upholstered side panels and chrome hardware in charcoal.",               base_cost: 155.00, stock_quantity: 7, weight: 40.0, color: "Charcoal",         material: "Engineered Wood", dimensions: { "width" => 25, "depth" => 16, "height" => 28 } }
].each { |attrs| upsert_product(attrs.merge(category: nightstands)) }

# ============================================================
# BEDROOM — Bedroom Sets
# ============================================================
bedroom_sets = Category.find_by!(name: "Bedroom Sets")

[
  {
    sku: "AF-B680-SET-Q",  name: "Maier Charcoal Queen Bedroom Set (5-Pc)",
    short_description: "Five-piece queen bedroom set including bed, dresser, mirror, nightstand, and chest. Contemporary charcoal upholstered styling.",
    base_cost: 1245.00, stock_quantity: 2, weight: 380.0, color: "Charcoal", material: "Engineered Wood",
    dimensions: { "width" => 66, "depth" => 92, "height" => 62 }, featured: true
  },
  {
    sku: "AF-B192-SET-Q",  name: "Cambeck Warm Brown Queen Bedroom Set (4-Pc)",
    short_description: "Four-piece queen set with panel bed, dresser, mirror, and nightstand in warm wire-brushed brown.",
    base_cost: 1095.00, stock_quantity: 2, weight: 360.0, color: "Warm Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 90, "height" => 57 }
  },
  {
    sku: "AF-B446-SET-Q",  name: "Trinell Brown Queen Bedroom Set (4-Pc)",
    short_description: "Rustic brown four-piece queen set with panel bed, dresser, mirror, and nightstand.",
    base_cost: 968.00, stock_quantity: 2, weight: 340.0, color: "Brown", material: "Wood Veneer",
    dimensions: { "width" => 65, "depth" => 88, "height" => 57 }
  },
  {
    sku: "AF-B743-SET-Q",  name: "Realyn Chipped White Queen Bedroom Set (5-Pc)",
    short_description: "Cottage chic five-piece queen set in chipped white including sleigh bed, dresser, mirror, two nightstands.",
    base_cost: 1385.00, stock_quantity: 1, weight: 420.0, color: "Chipped White", material: "Wood",
    dimensions: { "width" => 66, "depth" => 93, "height" => 64 }
  },
  {
    sku: "AF-B092-SET-Q",  name: "Bolanburg Queen Bedroom Set (4-Pc)",
    short_description: "Antique white and brown four-piece queen set with panel bed, dresser, mirror, and nightstand.",
    base_cost: 1128.00, stock_quantity: 2, weight: 370.0, color: "Antique White/Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 89, "height" => 60 }
  },
  {
    sku: "AF-B512-SET-Q",  name: "Alisdair Dark Brown Queen Bedroom Set (4-Pc)",
    short_description: "Traditional dark brown four-piece queen panel bed set with ornate carved details.",
    base_cost: 1048.00, stock_quantity: 2, weight: 355.0, color: "Dark Brown", material: "Wood",
    dimensions: { "width" => 65, "depth" => 89, "height" => 60 }
  },
  {
    sku: "AF-B211-SET-F",  name: "Neilsville Full Bedroom Set (4-Pc)",
    short_description: "Farmhouse-inspired four-piece full bedroom set in white and light brown.",
    base_cost: 885.00, stock_quantity: 3, weight: 310.0, color: "White/Light Brown", material: "Wood",
    dimensions: { "width" => 57, "depth" => 84, "height" => 53 }
  },
  {
    sku: "AF-B594-SET-Q",  name: "Robbinsdale Antique White Queen Bedroom Set (5-Pc)",
    short_description: "Vintage-inspired antique white five-piece queen bedroom set.",
    base_cost: 1445.00, stock_quantity: 1, weight: 435.0, color: "Antique White", material: "Wood",
    dimensions: { "width" => 66, "depth" => 93, "height" => 64 }
  },
  {
    sku: "AF-B090-SET-Q",  name: "Dolante Queen Bedroom Set (3-Pc)",
    short_description: "Modern upholstered three-piece queen set with bed, dresser, and nightstand in beige.",
    base_cost: 925.00, stock_quantity: 2, weight: 325.0, color: "Beige", material: "Fabric",
    dimensions: { "width" => 65, "depth" => 88, "height" => 48 }
  },
  {
    sku: "AF-B100-SET-K",  name: "Quinin Charcoal King Bedroom Set (4-Pc)",
    short_description: "Contemporary charcoal four-piece king upholstered bedroom set.",
    base_cost: 1185.00, stock_quantity: 1, weight: 395.0, color: "Charcoal", material: "Velvet/Engineered Wood",
    dimensions: { "width" => 82, "depth" => 90, "height" => 58 }
  }
].each { |attrs| upsert_product(attrs.merge(category: bedroom_sets)) }

# ============================================================
# DINING ROOM — Dining Sets
# ============================================================
dining_sets = Category.find_by!(name: "Dining Sets")

[
  {
    sku: "AF-D647-SET5",  name: "Bolanburg 5-Piece Dining Set",
    short_description: "Antique white and brown five-piece dining set with extension table and four upholstered side chairs.",
    base_cost: 648.00, stock_quantity: 2, weight: 225.0, color: "Antique White/Brown", material: "Wood",
    dimensions: { "width" => 60, "depth" => 36, "height" => 30 }, featured: true
  },
  {
    sku: "AF-D470-SET5",  name: "Grindleburg 5-Piece Dining Set",
    short_description: "Light brown five-piece dining set with rectangular table and four upholstered chairs.",
    base_cost: 598.00, stock_quantity: 2, weight: 210.0, color: "Light Brown", material: "Wood",
    dimensions: { "width" => 60, "depth" => 36, "height" => 30 }
  },
  {
    sku: "AF-D397-SET5",  name: "Rokane 5-Piece Dining Set",
    short_description: "Natural brown farmhouse five-piece dining set with round table and four slat-back chairs.",
    base_cost: 558.00, stock_quantity: 3, weight: 195.0, color: "Natural Brown", material: "Solid Wood",
    dimensions: { "width" => 54, "depth" => 54, "height" => 30 }
  },
  {
    sku: "AF-D600-SET5",  name: "Sommerford 5-Piece Dining Set",
    short_description: "Dark brown rustic five-piece dining set with turned-leg table and four slat-back chairs.",
    base_cost: 572.00, stock_quantity: 2, weight: 200.0, color: "Dark Brown", material: "Solid Wood",
    dimensions: { "width" => 58, "depth" => 36, "height" => 30 }
  },
  {
    sku: "AF-D372-SET5",  name: "Kavara 5-Piece Counter Dining Set",
    short_description: "Brown cherry counter-height five-piece dining set with extension table and four upholstered stools.",
    base_cost: 618.00, stock_quantity: 2, weight: 218.0, color: "Brown Cherry", material: "Wood",
    dimensions: { "width" => 54, "depth" => 35, "height" => 36 }
  },
  {
    sku: "AF-D731-SET5",  name: "Haddigan 5-Piece Counter Height Dining Set",
    short_description: "Dark brown counter-height five-piece set with slat-back barstools and turned-leg table.",
    base_cost: 545.00, stock_quantity: 3, weight: 192.0, color: "Dark Brown", material: "Solid Wood",
    dimensions: { "width" => 54, "depth" => 36, "height" => 36 }
  },
  {
    sku: "AF-D586-SET5",  name: "Valebeck 5-Piece Dining Set",
    short_description: "White and beige five-piece dining set with glass-top table and four upholstered chairs.",
    base_cost: 585.00, stock_quantity: 2, weight: 205.0, color: "White/Beige", material: "Wood/Glass",
    dimensions: { "width" => 55, "depth" => 36, "height" => 30 }
  },
  {
    sku: "AF-D743-SET5",  name: "Realyn 5-Piece Dining Set",
    short_description: "Chipped white cottage five-piece dining set with upholstered side chairs.",
    base_cost: 612.00, stock_quantity: 2, weight: 215.0, color: "Chipped White", material: "Wood",
    dimensions: { "width" => 58, "depth" => 38, "height" => 30 }
  },
  {
    sku: "AF-D754-SET5",  name: "Caitbrook Glass Top 5-Piece Dining Set",
    short_description: "Contemporary gray-wash five-piece set with rectangular glass top table and four upholstered chairs.",
    base_cost: 562.00, stock_quantity: 3, weight: 198.0, color: "Gray Wash", material: "Wood/Glass",
    dimensions: { "width" => 55, "depth" => 35, "height" => 30 }
  },
  {
    sku: "AF-D702-SET5",  name: "Chadoni 5-Piece Dining Set",
    short_description: "Medium brown five-piece dining set with trestle-style table and four upholstered side chairs.",
    base_cost: 588.00, stock_quantity: 2, weight: 208.0, color: "Medium Brown", material: "Wood",
    dimensions: { "width" => 60, "depth" => 36, "height" => 30 }
  }
].each { |attrs| upsert_product(attrs.merge(category: dining_sets)) }

# ============================================================
# DINING ROOM — Dining Tables
# ============================================================
dining_tables = Category.find_by!(name: "Dining Tables")

[
  { sku: "AF-D647-35",  name: "Bolanburg Rectangular Extension Dining Table",   short_description: "Antique white and brown extension table with 18\" leaf seating up to 8.",              base_cost: 348.00, stock_quantity: 4, weight: 128.0, color: "Antique White/Brown", material: "Wood",       dimensions: { "width" => 60, "depth" => 36, "height" => 30 } },
  { sku: "AF-D470-25",  name: "Grindleburg Dining Room Table",                  short_description: "Light brown rectangular dining table with plank-style top and large trestle base.",     base_cost: 295.00, stock_quantity: 5, weight: 118.0, color: "Light Brown",        material: "Wood",       dimensions: { "width" => 60, "depth" => 36, "height" => 30 } },
  { sku: "AF-D397-15",  name: "Rokane Round Dining Table",                      short_description: "Natural brown round pedestal dining table with turned column and claw feet.",           base_cost: 278.00, stock_quantity: 5, weight: 112.0, color: "Natural Brown",      material: "Solid Wood", dimensions: { "width" => 54, "depth" => 54, "height" => 30 } },
  { sku: "AF-D600-25",  name: "Sommerford Dining Room Table",                   short_description: "Rustic dark brown rectangular table with turned legs and center breadboard ends.",      base_cost: 285.00, stock_quantity: 5, weight: 115.0, color: "Dark Brown",        material: "Solid Wood", dimensions: { "width" => 60, "depth" => 36, "height" => 30 } },
  { sku: "AF-D372-25T", name: "Kavara Counter Height Dining Table",             short_description: "Brown cherry counter-height extension table with 12\" leaf and butterfly mechanism.",   base_cost: 318.00, stock_quantity: 4, weight: 125.0, color: "Brown Cherry",      material: "Wood",       dimensions: { "width" => 54, "depth" => 35, "height" => 36 } },
  { sku: "AF-D731-25",  name: "Haddigan Dark Brown Rectangular Dining Table",   short_description: "Casual dark brown table with planked top and chunky turned legs.",                     base_cost: 265.00, stock_quantity: 5, weight: 108.0, color: "Dark Brown",        material: "Solid Wood", dimensions: { "width" => 54, "depth" => 36, "height" => 30 } },
  { sku: "AF-D586-25",  name: "Valebeck White Glass-Top Dining Table",          short_description: "Contemporary white base dining table with tempered glass top and metal frame.",         base_cost: 292.00, stock_quantity: 4, weight: 122.0, color: "White",             material: "Metal/Glass",dimensions: { "width" => 55, "depth" => 36, "height" => 30 } },
  { sku: "AF-D743-25",  name: "Realyn Chipped White Dining Table",              short_description: "Cottage-style chipped white dining table with turned legs and center drawer.",          base_cost: 308.00, stock_quantity: 4, weight: 122.0, color: "Chipped White",    material: "Wood",       dimensions: { "width" => 60, "depth" => 38, "height" => 30 } },
  { sku: "AF-D754-25",  name: "Caitbrook Rectangular Glass Table",              short_description: "Gray wash rectangular dining table with tempered glass top and beveled edge.",          base_cost: 282.00, stock_quantity: 5, weight: 115.0, color: "Gray Wash",        material: "Wood/Glass", dimensions: { "width" => 55, "depth" => 36, "height" => 30 } },
  { sku: "AF-D702-25",  name: "Chadoni Dining Room Table",                      short_description: "Medium brown trestle-style dining table with farm-style base and plank top.",          base_cost: 298.00, stock_quantity: 4, weight: 118.0, color: "Medium Brown",      material: "Wood",       dimensions: { "width" => 60, "depth" => 36, "height" => 30 } }
].each { |attrs| upsert_product(attrs.merge(category: dining_tables)) }

# ============================================================
# DINING ROOM — Dining Chairs
# ============================================================
dining_chairs = Category.find_by!(name: "Dining Chairs")

[
  { sku: "AF-D647-01",  name: "Bolanburg Upholstered Side Chair",      short_description: "Antique white side chair with beige upholstered seat and decorative wood back.",          base_cost: 95.00, stock_quantity: 12, weight: 18.0, color: "Antique White/Beige",  material: "Wood/Fabric",      dimensions: { "width" => 18, "depth" => 20, "height" => 37 } },
  { sku: "AF-D470-01",  name: "Grindleburg Upholstered Dining Chair",  short_description: "Light brown upholstered dining side chair with slat back and padded seat.",              base_cost: 88.00, stock_quantity: 14, weight: 17.0, color: "Light Brown",           material: "Wood/Fabric",      dimensions: { "width" => 18, "depth" => 22, "height" => 38 } },
  { sku: "AF-D397-02",  name: "Rokane Slat-Back Side Chair",           short_description: "Natural brown solid wood dining chair with four vertical slats and padded seat.",        base_cost: 82.00, stock_quantity: 16, weight: 15.0, color: "Natural Brown",         material: "Solid Wood",       dimensions: { "width" => 17, "depth" => 21, "height" => 38 } },
  { sku: "AF-D600-02",  name: "Sommerford Dining Side Chair",          short_description: "Dark brown rustic dining chair with spindle back and contoured wood seat.",             base_cost: 78.00, stock_quantity: 16, weight: 14.0, color: "Dark Brown",            material: "Solid Wood",       dimensions: { "width" => 17, "depth" => 21, "height" => 38 } },
  { sku: "AF-D372-024", name: "Kavara Upholstered Counter Stool",      short_description: "Counter-height brown cherry stool with upholstered seat and ring-pull footrest.",        base_cost: 108.00, stock_quantity: 10, weight: 20.0, color: "Brown Cherry",          material: "Wood/Fabric",      dimensions: { "width" => 18, "depth" => 20, "height" => 41 } },
  { sku: "AF-D731-024", name: "Haddigan Counter Height Bar Stool",     short_description: "Dark brown counter-height stool with ladder-back and swivel seat.",                     base_cost: 95.00, stock_quantity: 12, weight: 17.0, color: "Dark Brown",            material: "Wood",             dimensions: { "width" => 18, "depth" => 18, "height" => 41 } },
  { sku: "AF-D586-01",  name: "Valebeck Upholstered Side Chair",       short_description: "White side chair with plush beige upholstered seat and metal footrest.",                base_cost: 92.00, stock_quantity: 12, weight: 18.0, color: "White/Beige",           material: "Metal/Fabric",     dimensions: { "width" => 18, "depth" => 20, "height" => 37 } },
  { sku: "AF-D116-01",  name: "Kimonte Side Chair (Black)",             short_description: "Contemporary black dining chair with faux leather seat and metal frame.",               base_cost: 78.00, stock_quantity: 14, weight: 14.0, color: "Black",                 material: "Metal/Faux Leather",dimensions: { "width" => 18, "depth" => 20, "height" => 35 } },
  { sku: "AF-D754-02",  name: "Caitbrook Upholstered Dining Chair",    short_description: "Gray wash side chair with upholstered seat and horizontal-slatted back.",               base_cost: 88.00, stock_quantity: 14, weight: 17.0, color: "Gray Wash",             material: "Wood/Fabric",      dimensions: { "width" => 18, "depth" => 22, "height" => 37 } },
  { sku: "AF-D702-01",  name: "Chadoni Upholstered Side Chair",        short_description: "Medium brown slat-back dining chair with padded fabric seat.",                          base_cost: 85.00, stock_quantity: 14, weight: 16.0, color: "Medium Brown",          material: "Wood/Fabric",      dimensions: { "width" => 18, "depth" => 21, "height" => 38 } }
].each { |attrs| upsert_product(attrs.merge(category: dining_chairs)) }

# ============================================================
# DINING ROOM — Buffets & Sideboards
# ============================================================
buffets = Category.find_by!(name: "Buffets & Sideboards")

[
  { sku: "AF-D647-60",  name: "Bolanburg Server",            short_description: "Antique white and brown dining server with three drawers and two door storage.",                     base_cost: 285.00, stock_quantity: 4, weight: 98.0, color: "Antique White/Brown",  material: "Wood",       dimensions: { "width" => 46, "depth" => 17, "height" => 38 } },
  { sku: "AF-D743-60",  name: "Realyn Dining Room Server",   short_description: "Chipped white cottage server with glass door curio cabinet and two lower drawers.",                 base_cost: 298.00, stock_quantity: 4, weight: 105.0, color: "Chipped White",       material: "Wood",       dimensions: { "width" => 48, "depth" => 17, "height" => 68 } },
  { sku: "AF-D446-60",  name: "Trinell Dining Room Server",  short_description: "Warm brown server with pipe-style accents and two door storage over one long drawer.",              base_cost: 262.00, stock_quantity: 4, weight: 88.0, color: "Brown",               material: "Wood Veneer", dimensions: { "width" => 44, "depth" => 16, "height" => 36 } },
  { sku: "AF-D731-60",  name: "Haddigan Server",             short_description: "Dark brown server with plank-style door fronts and metal hardware.",                                base_cost: 245.00, stock_quantity: 5, weight: 85.0, color: "Dark Brown",           material: "Solid Wood", dimensions: { "width" => 46, "depth" => 16, "height" => 37 } },
  { sku: "AF-D372-60",  name: "Kavara Server",               short_description: "Brown cherry buffet server with two glass doors and adjustable interior shelf.",                    base_cost: 278.00, stock_quantity: 4, weight: 92.0, color: "Brown Cherry",         material: "Wood",       dimensions: { "width" => 47, "depth" => 17, "height" => 40 } },
  { sku: "AF-D192-60",  name: "Cambeck Server",              short_description: "Warm brown wire-brushed server with two drawers and two door storage.",                             base_cost: 268.00, stock_quantity: 4, weight: 90.0, color: "Warm Brown",           material: "Wood",       dimensions: { "width" => 46, "depth" => 17, "height" => 38 } },
  { sku: "AF-D550-60",  name: "Hammis Server",               short_description: "Two-tone white and brown server with three center drawers and two side cabinets.",                  base_cost: 272.00, stock_quantity: 4, weight: 95.0, color: "White/Brown",          material: "Wood",       dimensions: { "width" => 52, "depth" => 17, "height" => 38 } },
  { sku: "AF-D600-60",  name: "Sommerford Server",           short_description: "Dark brown rustic server with plank-style doors and two-drawer center section.",                    base_cost: 255.00, stock_quantity: 4, weight: 88.0, color: "Dark Brown",           material: "Solid Wood", dimensions: { "width" => 48, "depth" => 17, "height" => 37 } },
  { sku: "AF-D754-60",  name: "Caitbrook Server",            short_description: "Gray wash server with framed door fronts and decorative hardware.",                                 base_cost: 260.00, stock_quantity: 4, weight: 90.0, color: "Gray Wash",            material: "Wood",       dimensions: { "width" => 46, "depth" => 17, "height" => 38 } },
  { sku: "AF-D702-60",  name: "Chadoni Server",              short_description: "Medium brown dining server with glass-insert door fronts and adjustable shelf.",                    base_cost: 268.00, stock_quantity: 4, weight: 92.0, color: "Medium Brown",         material: "Wood",       dimensions: { "width" => 48, "depth" => 17, "height" => 39 } }
].each { |attrs| upsert_product(attrs.merge(category: buffets)) }

# ============================================================
# HOME OFFICE — Desks
# ============================================================
desks = Category.find_by!(name: "Desks")

[
  { sku: "AF-H200-44",  name: "Realyn Chipped White Credenza Desk",  short_description: "Chipped white credenza desk with four drawers and open hutch shelf above.",                     base_cost: 285.00, stock_quantity: 4, weight: 115.0, color: "Chipped White",    material: "Wood",            dimensions: { "width" => 55, "depth" => 24, "height" => 30 } },
  { sku: "AF-H200-29",  name: "Camiburg Warm Brown Home Office Desk",short_description: "Warm brown L-shaped desk with two drawers and open bookcase storage on one side.",               base_cost: 318.00, stock_quantity: 3, weight: 125.0, color: "Warm Brown",      material: "Wood",            dimensions: { "width" => 60, "depth" => 47, "height" => 30 } },
  { sku: "AF-H200-11",  name: "Neilsville Home Office Desk",          short_description: "White and light brown farmhouse writing desk with center drawer and open shelves.",              base_cost: 195.00, stock_quantity: 5, weight: 85.0, color: "White/Light Brown", material: "Wood",            dimensions: { "width" => 48, "depth" => 22, "height" => 30 } },
  { sku: "AF-H200-21",  name: "Thadamere Black Home Office Desk",     short_description: "Contemporary black home office desk with two drawers and cable management port.",               base_cost: 225.00, stock_quantity: 5, weight: 98.0, color: "Black",            material: "Engineered Wood", dimensions: { "width" => 52, "depth" => 22, "height" => 30 } },
  { sku: "AF-H200-14",  name: "Dorrinson Home Office Desk",           short_description: "Two-tone gray-over-black home office desk with file drawer and keyboard tray.",                 base_cost: 212.00, stock_quantity: 5, weight: 95.0, color: "Gray/Black",       material: "Engineered Wood", dimensions: { "width" => 50, "depth" => 22, "height" => 30 } },
  { sku: "AF-H200-22",  name: "Mirimyn Cottage White Small Desk",     short_description: "Petite cottage white writing desk with single drawer and tapered legs.",                        base_cost: 175.00, stock_quantity: 6, weight: 72.0, color: "Cottage White",    material: "Wood",            dimensions: { "width" => 40, "depth" => 19, "height" => 30 } },
  { sku: "AF-H200-15",  name: "Brennan 60\" Computer Desk",           short_description: "Dark brown classic computer desk with keyboard tray and three drawers.",                        base_cost: 248.00, stock_quantity: 4, weight: 108.0, color: "Dark Brown",       material: "Wood",            dimensions: { "width" => 60, "depth" => 24, "height" => 30 } },
  { sku: "AF-H200-24",  name: "Zendex Corner Workstation",            short_description: "Black L-shaped corner workstation with two side towers and floating keyboard shelf.",           base_cost: 295.00, stock_quantity: 3, weight: 122.0, color: "Black",            material: "Engineered Wood", dimensions: { "width" => 72, "depth" => 50, "height" => 30 } },
  { sku: "AF-H200-31",  name: "Cazenfeld Home Office Desk",           short_description: "Antique white writing desk with ornate carving, one drawer, and turned legs.",                  base_cost: 228.00, stock_quantity: 4, weight: 88.0, color: "Antique White",    material: "Wood",            dimensions: { "width" => 50, "depth" => 22, "height" => 30 } },
  { sku: "AF-H200-33",  name: "Arlenbry Writing Desk",                short_description: "Gray finish contemporary writing desk with open shelf and two small side drawers.",              base_cost: 188.00, stock_quantity: 5, weight: 78.0, color: "Gray",             material: "Wood",            dimensions: { "width" => 48, "depth" => 22, "height" => 30 } }
].each { |attrs| upsert_product(attrs.merge(category: desks)) }

# ============================================================
# HOME OFFICE — Office Chairs
# ============================================================
office_chairs = Category.find_by!(name: "Office Chairs")

[
  { sku: "AF-H205-01A", name: "Baraga Swivel Desk Chair",       short_description: "Dark brown swivel office chair with adjustable height and armrests.",                  base_cost: 145.00, stock_quantity: 7, weight: 38.0, color: "Dark Brown",      material: "Faux Leather",  dimensions: { "width" => 26, "depth" => 27, "height" => 44 } },
  { sku: "AF-H200-01A", name: "Realyn White Swivel Desk Chair", short_description: "Cottage white swivel desk chair with cushioned seat and adjustable height.",            base_cost: 138.00, stock_quantity: 7, weight: 35.0, color: "Chipped White",   material: "Fabric",        dimensions: { "width" => 25, "depth" => 25, "height" => 42 } },
  { sku: "AF-H206-01A", name: "Beauenali Swivel Desk Chair",    short_description: "Gray home office swivel chair with casual profile, padded arms, and caster wheels.",   base_cost: 128.00, stock_quantity: 8, weight: 32.0, color: "Gray",            material: "Fabric",        dimensions: { "width" => 24, "depth" => 24, "height" => 38 } },
  { sku: "AF-H207-01A", name: "Raelynn Swivel Desk Chair",      short_description: "White and chrome office chair with upholstered seat and chrome ring swivel base.",      base_cost: 155.00, stock_quantity: 6, weight: 30.0, color: "White/Chrome",    material: "Fabric/Metal",  dimensions: { "width" => 23, "depth" => 23, "height" => 35 } },
  { sku: "AF-H208-01A", name: "Crossmore Office Swivel Chair",  short_description: "Black tufted office chair with padded arms and pneumatic height adjustment.",           base_cost: 165.00, stock_quantity: 6, weight: 36.0, color: "Black",           material: "Faux Leather",  dimensions: { "width" => 26, "depth" => 26, "height" => 46 } },
  { sku: "AF-H209-01A", name: "Aleenyah Office Chair",          short_description: "Contemporary mesh-back office chair with lumbar support and adjustable armrests.",      base_cost: 178.00, stock_quantity: 5, weight: 34.0, color: "Black",           material: "Mesh/Fabric",   dimensions: { "width" => 25, "depth" => 25, "height" => 45 } },
  { sku: "AF-H210-01A", name: "Krosteman Adjustable Chair",     short_description: "Black bonded leather executive chair with high back and padded headrest.",               base_cost: 192.00, stock_quantity: 5, weight: 42.0, color: "Black",           material: "Bonded Leather",dimensions: { "width" => 27, "depth" => 27, "height" => 50 } },
  { sku: "AF-H211-01A", name: "Topline Fabric Office Chair",    short_description: "Stone blue fabric office chair with adjustable lumbar support and tilt tension.",        base_cost: 148.00, stock_quantity: 6, weight: 32.0, color: "Stone Blue",      material: "Fabric",        dimensions: { "width" => 25, "depth" => 26, "height" => 43 } },
  { sku: "AF-H212-01A", name: "Berneen Swivel Desk Chair",      short_description: "Ivory fabric small-space swivel chair with compact base and easy-glide casters.",       base_cost: 122.00, stock_quantity: 8, weight: 28.0, color: "Ivory",           material: "Fabric",        dimensions: { "width" => 22, "depth" => 22, "height" => 36 } },
  { sku: "AF-H213-01A", name: "Sorbus Executive Office Chair",  short_description: "Dark gray executive chair with padded flip-up arms and pneumatic seat height adjustment.",base_cost: 185.00, stock_quantity: 5, weight: 40.0, color: "Dark Gray",       material: "Fabric",        dimensions: { "width" => 27, "depth" => 27, "height" => 48 } }
].each { |attrs| upsert_product(attrs.merge(category: office_chairs)) }

# ============================================================
# HOME OFFICE — Bookcases
# ============================================================
bookcases = Category.find_by!(name: "Bookcases")

[
  { sku: "AF-H200-17",  name: "Realyn Chipped White Bookcase",      short_description: "Cottage chipped white large bookcase with glass doors and four adjustable shelves.",     base_cost: 248.00, stock_quantity: 4, weight: 112.0, color: "Chipped White",    material: "Wood",            dimensions: { "width" => 34, "depth" => 14, "height" => 78 } },
  { sku: "AF-H200-66",  name: "Camiburg Bookcase",                  short_description: "Warm brown large bookcase with two glass doors and five open display shelves.",          base_cost: 268.00, stock_quantity: 3, weight: 118.0, color: "Warm Brown",       material: "Wood",            dimensions: { "width" => 36, "depth" => 14, "height" => 78 } },
  { sku: "AF-H200-76",  name: "Trinell Large Bookcase",              short_description: "Brown rustic bookcase with pipe-style accents and three open shelves.",                  base_cost: 228.00, stock_quantity: 4, weight: 105.0, color: "Brown",            material: "Wood Veneer",     dimensions: { "width" => 32, "depth" => 13, "height" => 72 } },
  { sku: "AF-H200-36",  name: "Bolanburg Large Bookcase",            short_description: "Antique white and brown bookcase with glass doors over wood panel lower doors.",         base_cost: 272.00, stock_quantity: 3, weight: 120.0, color: "Antique White/Brown",material: "Wood",            dimensions: { "width" => 38, "depth" => 15, "height" => 80 } },
  { sku: "AF-H200-86",  name: "Mirimyn Cottage White Bookcase",      short_description: "Small cottage white bookcase with open shelves and one lower door.",                     base_cost: 148.00, stock_quantity: 6, weight: 72.0, color: "Cottage White",     material: "Wood",            dimensions: { "width" => 26, "depth" => 12, "height" => 60 } },
  { sku: "AF-H200-96",  name: "Jakmore Large Bookcase",              short_description: "Dark charcoal large bookcase with two lower cabinets and four open shelves.",            base_cost: 295.00, stock_quantity: 3, weight: 125.0, color: "Dark Charcoal",    material: "Wood/Metal",      dimensions: { "width" => 36, "depth" => 14, "height" => 80 } },
  { sku: "AF-H200-56",  name: "Neilsville White Bookcase",           short_description: "Two-tone white and light brown tall bookcase with five shelves and beadboard backing.",  base_cost: 185.00, stock_quantity: 5, weight: 85.0, color: "White/Light Brown", material: "Wood",            dimensions: { "width" => 30, "depth" => 12, "height" => 71 } },
  { sku: "AF-H200-46",  name: "Arlenbry Gray Large Bookcase",        short_description: "Gray finish modern bookcase with five open adjustable shelves.",                         base_cost: 175.00, stock_quantity: 5, weight: 80.0, color: "Gray",             material: "Engineered Wood", dimensions: { "width" => 30, "depth" => 12, "height" => 71 } },
  { sku: "AF-H200-37",  name: "Cazenfeld Antique White Bookcase",    short_description: "Antique white ornate bookcase with glass doors and carved crown molding.",               base_cost: 262.00, stock_quantity: 3, weight: 115.0, color: "Antique White",    material: "Wood",            dimensions: { "width" => 34, "depth" => 14, "height" => 78 } },
  { sku: "AF-H200-27",  name: "Larilyn Accent Bookcase",             short_description: "Weathered dark brown accent bookcase with woven rattan door inserts.",                   base_cost: 222.00, stock_quantity: 4, weight: 98.0, color: "Weathered Brown",   material: "Wood/Rattan",     dimensions: { "width" => 32, "depth" => 13, "height" => 68 } }
].each { |attrs| upsert_product(attrs.merge(category: bookcases)) }

# ============================================================
# OUTDOOR
# ============================================================
outdoor = Category.find_by!(name: "Outdoor")

[
  {
    sku: "AF-P791-080",  name: "Coastline Bay 4-Piece Outdoor Set",
    short_description: "All-weather white outdoor set including sofa, loveseat, chair, and cocktail table.",
    base_cost: 648.00, stock_quantity: 2, weight: 145.0, color: "White", material: "HDPE Wicker",
    dimensions: { "width" => 84, "depth" => 36, "height" => 34 }, featured: true
  },
  {
    sku: "AF-P215-082",  name: "Beachcroft Outdoor Sofa",
    short_description: "Beige outdoor sofa with all-weather cushions and eucalyptus wood frame.",
    base_cost: 445.00, stock_quantity: 3, weight: 88.0, color: "Beige", material: "Eucalyptus/Fabric",
    dimensions: { "width" => 78, "depth" => 34, "height" => 33 }
  },
  {
    sku: "AF-P801-083",  name: "Barn Cove 4-Piece Outdoor Dining Set",
    short_description: "Gray wash outdoor four-piece dining set with sling chairs and extension table.",
    base_cost: 595.00, stock_quantity: 2, weight: 132.0, color: "Gray Wash", material: "Aluminum",
    dimensions: { "width" => 63, "depth" => 36, "height" => 30 }
  },
  {
    sku: "AF-P332-081",  name: "Peachstone 3-Piece Outdoor Set",
    short_description: "Beige three-piece outdoor bistro set with two chairs and one side table.",
    base_cost: 295.00, stock_quantity: 4, weight: 62.0, color: "Beige", material: "Steel",
    dimensions: { "width" => 36, "depth" => 36, "height" => 28 }
  },
  {
    sku: "AF-P780-080",  name: "Burnella 4-Piece Outdoor Sectional",
    short_description: "Chocolate brown outdoor sectional with modular pieces and weather-resistant cushions.",
    base_cost: 755.00, stock_quantity: 2, weight: 165.0, color: "Chocolate Brown", material: "Steel/Fabric",
    dimensions: { "width" => 120, "depth" => 82, "height" => 32 }
  },
  {
    sku: "AF-P792-081",  name: "Eden Town 2-Piece Outdoor Seating",
    short_description: "Steel two-piece outdoor loveseat set with all-weather wicker and cushions.",
    base_cost: 385.00, stock_quantity: 3, weight: 92.0, color: "Black/Beige", material: "Steel/Wicker",
    dimensions: { "width" => 60, "depth" => 32, "height" => 32 }
  },
  {
    sku: "AF-P360-074",  name: "Vallerie Outdoor Rocking Chair (Set of 2)",
    short_description: "White outdoor rocking chair with slatted back and seat for front porch use.",
    base_cost: 185.00, stock_quantity: 5, weight: 35.0, color: "White", material: "Polypropylene",
    dimensions: { "width" => 26, "depth" => 34, "height" => 40 }
  },
  {
    sku: "AF-P459-082",  name: "Partanna Outdoor Loveseat",
    short_description: "Brown outdoor loveseat with water-resistant cushions and rust-resistant steel frame.",
    base_cost: 322.00, stock_quantity: 3, weight: 72.0, color: "Brown/Beige", material: "Steel",
    dimensions: { "width" => 60, "depth" => 32, "height" => 32 }
  },
  {
    sku: "AF-P458-065",  name: "Surfside 5-Piece Outdoor Dining Set",
    short_description: "Steel outdoor five-piece dining set with umbrella hole and sling-back chairs.",
    base_cost: 545.00, stock_quantity: 2, weight: 125.0, color: "Tan/Beige", material: "Steel/Fabric",
    dimensions: { "width" => 42, "depth" => 42, "height" => 30 }
  },
  {
    sku: "AF-P210-085",  name: "Kendrick Outdoor Bench",
    short_description: "Classic white outdoor bench with slatted back and armrests. Seats two to three.",
    base_cost: 162.00, stock_quantity: 5, weight: 42.0, color: "White", material: "Polypropylene",
    dimensions: { "width" => 48, "depth" => 22, "height" => 35 }
  }
].each { |attrs| upsert_product(attrs.merge(category: outdoor)) }

# ============================================================
# MATTRESSES
# ============================================================
mattresses = Category.find_by!(name: "Mattresses")

[
  {
    sku: "AF-M62721",    name: "Chime 12\" Medium Hybrid Queen Mattress",
    short_description: "12-inch hybrid queen mattress with individually wrapped coils and memory foam comfort layers. Medium feel.",
    base_cost: 295.00, stock_quantity: 6, weight: 85.0, color: "White", material: "Foam/Coil Hybrid",
    dimensions: { "width" => 60, "depth" => 80, "height" => 12 }, featured: true
  },
  {
    sku: "AF-M62731",    name: "Chime 10\" Medium Firm Queen Mattress",
    short_description: "10-inch foam queen mattress with fiber-fill quilt top and CertiPUR-US certified foam.",
    base_cost: 228.00, stock_quantity: 7, weight: 70.0, color: "White", material: "Memory Foam",
    dimensions: { "width" => 60, "depth" => 80, "height" => 10 }
  },
  {
    sku: "AF-M62741",    name: "Chime Elite 12\" Plush Hybrid Queen Mattress",
    short_description: "Premium 12-inch plush hybrid mattress with gel-infused memory foam and pocketed coil support.",
    base_cost: 365.00, stock_quantity: 5, weight: 92.0, color: "White", material: "Foam/Coil Hybrid",
    dimensions: { "width" => 60, "depth" => 80, "height" => 12 }
  },
  {
    sku: "AF-M62751",    name: "Gruve 12\" Hybrid King Mattress",
    short_description: "12-inch firm hybrid king mattress with breathable cover and zoned support coils.",
    base_cost: 428.00, stock_quantity: 4, weight: 112.0, color: "White", material: "Foam/Coil Hybrid",
    dimensions: { "width" => 76, "depth" => 80, "height" => 12 }
  },
  {
    sku: "AF-M62761",    name: "Bonnie 10\" Bonell Queen Mattress",
    short_description: "Budget-friendly 10-inch innerspring queen mattress with bonnell coil system and soft quilt top.",
    base_cost: 185.00, stock_quantity: 8, weight: 65.0, color: "White", material: "Innerspring",
    dimensions: { "width" => 60, "depth" => 80, "height" => 10 }
  },
  {
    sku: "AF-M82720",    name: "Bonita Springs 14\" Plush Pillow Top Queen Mattress",
    short_description: "Luxurious 14-inch pillow-top queen mattress with pocketed coils and multiple foam comfort layers.",
    base_cost: 498.00, stock_quantity: 3, weight: 108.0, color: "White", material: "Foam/Pocketed Coil",
    dimensions: { "width" => 60, "depth" => 80, "height" => 14 }
  },
  {
    sku: "AF-M62771",    name: "Chime Express 10\" Firm Twin Mattress",
    short_description: "10-inch firm foam twin mattress with adaptive comfort foam and removable cover.",
    base_cost: 148.00, stock_quantity: 9, weight: 38.0, color: "White", material: "Memory Foam",
    dimensions: { "width" => 38, "depth" => 75, "height" => 10 }
  },
  {
    sku: "AF-M62781",    name: "Ashley Sleep 8\" Mattress Queen",
    short_description: "Everyday value 8-inch queen mattress with quilted pillow top and continuous coil system.",
    base_cost: 168.00, stock_quantity: 8, weight: 58.0, color: "White", material: "Innerspring",
    dimensions: { "width" => 60, "depth" => 80, "height" => 8 }
  },
  {
    sku: "AF-M62791",    name: "Sierra Sleep 10\" Medium King Mattress",
    short_description: "10-inch medium king mattress with individually wrapped coils and quilted euro top.",
    base_cost: 358.00, stock_quantity: 4, weight: 95.0, color: "White", material: "Foam/Coil Hybrid",
    dimensions: { "width" => 76, "depth" => 80, "height" => 10 }
  },
  {
    sku: "AF-M82730",    name: "Posturepedic 12\" Tight-Top Firm Queen Mattress",
    short_description: "12-inch firm tight-top queen mattress with gel memory foam and reinforced edge support coils.",
    base_cost: 418.00, stock_quantity: 3, weight: 100.0, color: "White", material: "Foam/Coil Hybrid",
    dimensions: { "width" => 60, "depth" => 80, "height" => 12 }
  }
].each { |attrs| upsert_product(attrs.merge(category: mattresses)) }

total = Product.count
puts "  ✓ Ashley product catalog seeded — #{total} total products in database"
