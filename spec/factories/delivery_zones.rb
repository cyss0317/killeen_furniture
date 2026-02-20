FactoryBot.define do
  factory :delivery_zone do
    sequence(:name) { |n| "Zone #{n}" }
    zip_codes         { %w[76541 76542 76543] }
    base_rate         { 75.00 }
    per_item_fee      { 10.00 }
    large_item_surcharge { 25.00 }
    active            { true }
  end
end
