FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "#{Faker::Commerce.department(max: 1)} #{n}" }
    parent { nil }
    position { 0 }
  end
end
