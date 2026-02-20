FactoryBot.define do
  factory :order do
    association :user
    sequence(:order_number) { |n| "KF-2026-#{n.to_s.rjust(8, '0')}" }
    status           { :pending }
    source           { :web_customer }
    subtotal         { Faker::Commerce.price(range: 200.0..3000.0).round(2) }
    shipping_amount  { Faker::Commerce.price(range: 75.0..200.0).round(2) }
    tax_amount       { 0 }
    grand_total      { subtotal + shipping_amount }
    shipping_address do
      {
        "full_name"      => user.full_name,
        "street_address" => Faker::Address.street_address,
        "city"           => "Killeen",
        "state"          => "TX",
        "zip_code"       => "76541"
      }
    end
    notes { nil }

    trait :admin_manual do
      source { :admin_manual }
    end

    trait :phone do
      source { :phone }
    end

    trait :paid do
      status { :paid }
    end

    trait :scheduled do
      status { :scheduled_for_delivery }
    end

    trait :out_for_delivery do
      status { :out_for_delivery }
    end

    trait :assigned do
      status { :scheduled_for_delivery }
      association :assigned_to, factory: [:user, :delivery_admin]
    end

    trait :delivered do
      status { :delivered }
      delivered_at { Faker::Time.backward(days: 14, period: :day) }
      association :assigned_to,  factory: [:user, :delivery_admin]
      association :delivered_by, factory: [:user, :delivery_admin]
    end

    trait :canceled do
      status { :canceled }
    end

    trait :guest do
      user       { nil }
      guest_name  { Faker::Name.name }
      guest_email { Faker::Internet.email }
      guest_phone { Faker::PhoneNumber.cell_phone_in_e164 }
      shipping_address do
        {
          "full_name"      => guest_name,
          "street_address" => Faker::Address.street_address,
          "city"           => "Killeen",
          "state"          => "TX",
          "zip_code"       => "76541"
        }
      end
    end
  end
end
