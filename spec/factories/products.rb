FactoryBot.define do
  factory :product do
    association :category
    sequence(:name)  { |n| "#{Faker::Commerce.product_name} #{n}" }
    sequence(:sku)   { |n| "FACTORY-#{n.to_s.rjust(5, '0')}" }
    base_cost        { Faker::Commerce.price(range: 100.0..2000.0).round(2) }
    markup_percentage { 35.0 }
    stock_quantity   { Faker::Number.between(from: 1, to: 50) }
    status           { :published }
    weight           { Faker::Number.decimal(l_digits: 2, r_digits: 1).to_f }
    featured         { false }

    trait :out_of_stock do
      stock_quantity { 0 }
    end

    trait :draft do
      status { :draft }
    end

    trait :featured do
      featured { true }
    end
  end
end
