class ShippingCalculator
  Result = Struct.new(:cost, :zone, :error, keyword_init: true) do
    def success?
      error.nil?
    end
  end

  def self.call(cart:, zip_code:)
    new(cart: cart, zip_code: zip_code).call
  end

  def initialize(cart:, zip_code:)
    @cart     = cart
    @zip_code = zip_code.to_s.strip
  end

  def call
    return Result.new(cost: 0, zone: nil, error: "Please enter a ZIP code") if @zip_code.blank?

    zone = DeliveryZone.find_by_zip(@zip_code)
    unless zone
      return Result.new(
        cost:  0,
        zone:  nil,
        error: "We currently deliver only to selected local areas. ZIP code #{@zip_code} is not in our delivery area."
      )
    end

    cost = zone.base_rate.to_f
    cost += zone.per_item_fee.to_f * @cart.total_items
    cost += large_item_surcharge(zone)

    Result.new(cost: cost.round(2), zone: zone, error: nil)
  end

  private

  def large_item_surcharge(zone)
    large_count = @cart.cart_items.includes(:product).count { |ci| ci.product.large_item? }
    zone.large_item_surcharge.to_f * large_count
  end
end
