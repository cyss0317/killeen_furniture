FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    phone      { Faker::PhoneNumber.cell_phone_in_e164 }
    password   { "password123!" }
    role       { :customer }
    admin_kind { nil }

    trait :admin do
      role { :admin }
    end

    trait :ops_admin do
      role       { :admin }
      admin_kind { :ops }
    end

    trait :delivery_admin do
      role       { :admin }
      admin_kind { :delivery }
    end

    trait :super_admin do
      role { :super_admin }
    end
  end
end
