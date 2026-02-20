FactoryBot.define do
  factory :order_item do
    association :order
    association :product
    quantity          { Faker::Number.between(from: 1, to: 3) }
    unit_price        { product.selling_price }
    unit_cost         { product.base_cost }
    markup_percentage { product.markup_percentage }
    product_name      { product.name }
    product_sku       { product.sku }
  end
end
