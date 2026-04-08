module ApplicationHelper
  DEFAULT_DESCRIPTION = "Shop quality Ashley Furniture at Warehouse Furniture — sofas, beds, " \
                        "dining sets, and more with local delivery in the Killeen, TX area."

  def meta_title
    content_for?(:title) ? content_for(:title) : APP_NAME
  end

  def meta_description
    content_for?(:description) ? content_for(:description) : DEFAULT_DESCRIPTION
  end

  def meta_image
    content_for?(:og_image) ? content_for(:og_image) : "#{request.base_url}/icon.png"
  end

  def canonical_url
    request.url.split("?").first
  end

  def noindex_page?
    request.path.start_with?("/admin", "/super_admin", "/delivery", "/account",
                             "/checkout", "/cart", "/users", "/webhooks")
  end


  def google_maps_url(address_hash)
    parts = [
      address_hash["street_address"],
      address_hash["city"],
      address_hash["state"],
      address_hash["zip_code"]
    ].compact
    "https://www.google.com/maps/search/?api=1&query=#{CGI.escape(parts.join(', '))}"
  end

  # Renders the best available image for a product.
  # Prefers vendor_image_urls (direct URL), falls back to ActiveStorage variant.
  # `size` is used only for ActiveStorage variants (e.g. [400, 400]).
  # Returns nil if no image is available.
  # Maps every raw product color value → a canonical display group.
  # Used to collapse 60+ raw values into 7 groups for filters.
  COLOR_GROUP_MAP = {
    # White / Cream
    "Alabaster"           => "White / Cream",
    "Antique White"       => "White / Cream",
    "Antique White/Beige" => "White / Cream",
    "Antique White/Brown" => "White / Cream",
    "Bisque"              => "White / Cream",
    "Bone White"          => "White / Cream",
    "Chipped White"       => "White / Cream",
    "Cottage White"       => "White / Cream",
    "Ivory"               => "White / Cream",
    "White"               => "White / Cream",
    "White/Beige"         => "White / Cream",
    "White/Brown"         => "White / Cream",
    "White/Chrome"        => "White / Cream",
    "White/Dark Brown"    => "White / Cream",
    "White/Gray"          => "White / Cream",
    "White/Light Brown"   => "White / Cream",
    # Beige / Tan / Natural
    "Beige"               => "Beige / Tan",
    "Black/Beige"         => "Beige / Tan",
    "Brown/Beige"         => "Beige / Tan",
    "Natural"             => "Beige / Tan",
    "Natural Brown"       => "Beige / Tan",
    "Oak"                 => "Beige / Tan",
    "Tan/Beige"           => "Beige / Tan",
    "Taupe"               => "Beige / Tan",
    # Gray
    "Alloy"               => "Gray",
    "Charcoal"            => "Gray",
    "Charcoal/Chrome"     => "Gray",
    "Cobblestone"         => "Gray",
    "Dark Charcoal"       => "Gray",
    "Dark Gray"           => "Gray",
    "Fog"                 => "Gray",
    "Gray"                => "Gray",
    "Gray Wash"           => "Gray",
    "Gray/Black"          => "Gray",
    "Nickel"              => "Gray",
    "Quartz"              => "Gray",
    "Slate"               => "Gray",
    "Smoke"               => "Gray",
    "Stone Gray"          => "Gray",
    "Two-Tone Gray/Brown" => "Gray",
    # Brown
    "BROWN"               => "Brown",
    "Brown"               => "Brown",
    "Brown Cherry"        => "Brown",
    "Burnished Brown"     => "Brown",
    "Chocolate Brown"     => "Brown",
    "Coffee"              => "Brown",
    "Dark Brown"          => "Brown",
    "Espresso"            => "Brown",
    "Grayish Brown"       => "Brown",
    "Java"                => "Brown",
    "Light Brown"         => "Brown",
    "Medium Brown"        => "Brown",
    "Reddish Brown"       => "Brown",
    "Rustic Brown"        => "Brown",
    "Two-Tone Brindle"    => "Brown",
    "Walnut"              => "Brown",
    "Warm Brown"          => "Brown",
    "Weathered Brown"     => "Brown",
    # Black
    "Black"               => "Black",
    "Black/Gray"          => "Black",
    # Blue / Navy
    "Blue"                => "Blue / Navy",
    "Navy"                => "Blue / Navy",
    "Stone Blue"          => "Blue / Navy",
    # Multi / Other
    "Coral"               => "Multi / Other",
    "Multi-color"         => "Multi / Other",
  }.freeze

  # All raw color strings that belong to a given group name.
  def self.colors_in_group(group)
    COLOR_GROUP_MAP.select { |_, g| g == group }.keys
  end

  # Ordered list of [group_name, css_swatch] pairs for display.
  COLOR_GROUP_SWATCHES = [
    ["White / Cream", "#f5f0e8"],
    ["Beige / Tan",   "#d2b48c"],
    ["Gray",          "#9e9e9e"],
    ["Brown",         "#795548"],
    ["Black",         "#212121"],
    ["Blue / Navy",   "#1a237e"],
    ["Multi / Other", "linear-gradient(135deg,#e53935 25%,#1e88e5 25% 50%,#43a047 50% 75%,#fdd835 75%)"],
  ].freeze

  # Maps a color name string to a CSS color value for swatches.
  # Falls back to a neutral gray for unrecognized names.
  COLOR_SWATCHES = {
    "white"          => "#ffffff",
    "off white"      => "#f5f0e8",
    "cream"          => "#f5f0dc",
    "ivory"          => "#fffff0",
    "beige"          => "#f5f5dc",
    "tan"            => "#d2b48c",
    "sand"           => "#c2b280",
    "champagne"      => "#f7e7ce",
    "gray"           => "#9e9e9e",
    "grey"           => "#9e9e9e",
    "light gray"     => "#d3d3d3",
    "light grey"     => "#d3d3d3",
    "dark gray"      => "#616161",
    "dark grey"      => "#616161",
    "charcoal"       => "#36454f",
    "slate"          => "#708090",
    "black"          => "#212121",
    "brown"          => "#795548",
    "dark brown"     => "#4e342e",
    "light brown"    => "#a1887f",
    "mocha"          => "#6d4c41",
    "chocolate"      => "#5d4037",
    "espresso"       => "#3e2723",
    "walnut"         => "#5c3a1e",
    "chestnut"       => "#954535",
    "caramel"        => "#c68642",
    "cognac"         => "#9a463d",
    "russet"         => "#80461b",
    "sienna"         => "#a0522d",
    "navy"           => "#1a237e",
    "navy blue"      => "#1a237e",
    "blue"           => "#1565c0",
    "light blue"     => "#64b5f6",
    "teal"           => "#00695c",
    "green"          => "#2e7d32",
    "sage"           => "#8fbc8f",
    "olive"          => "#808000",
    "red"            => "#c62828",
    "burgundy"       => "#7b1fa2",
    "wine"           => "#722f37",
    "mauve"          => "#e0b4c0",
    "blush"          => "#f9a8b4",
    "pink"           => "#e91e63",
    "purple"         => "#6a1b9a",
    "lavender"       => "#b39ddb",
    "yellow"         => "#f9a825",
    "gold"           => "#ffd700",
    "orange"         => "#e65100",
    "rust"           => "#b7410e",
    "terracotta"     => "#c0533a",
    "natural"        => "#d4c5a9",
    "linen"          => "#faf0e6",
    "taupe"          => "#b9a99a",
    "stone"          => "#a8a39d",
    "silver"         => "#bdbdbd",
    "multi"          => "linear-gradient(135deg, #e53935 25%, #1e88e5 25% 50%, #43a047 50% 75%, #fdd835 75%)",
    "multicolor"     => "linear-gradient(135deg, #e53935 25%, #1e88e5 25% 50%, #43a047 50% 75%, #fdd835 75%)"
  }.freeze

  def color_swatch_css(color_name)
    COLOR_SWATCHES[color_name.to_s.downcase.strip] || "#9e9e9e"
  end

  def color_swatch_for_group(group_name)
    COLOR_GROUP_SWATCHES.find { |g, _| g == group_name }&.last || "#9e9e9e"
  end

  def product_image_tag(product, size: [400, 400], **opts)
    if product.vendor_image_urls.present?
      image_tag product.vendor_image_urls.first, **opts
    elsif product.images.attached? && product.primary_image
      image_tag product.primary_image.variant(resize_to_fill: size), **opts
    end
  end
end
