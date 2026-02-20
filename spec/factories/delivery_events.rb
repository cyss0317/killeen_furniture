FactoryBot.define do
  factory :delivery_event do
    association :order
    association :created_by, factory: :user
    status { :assigned }
    note   { "Assigned to driver" }

    trait :delivered do
      status { :delivered }
      note   { "Marked as delivered" }
    end

    trait :failed do
      status { :failed }
      note   { "Customer not available" }
    end
  end
end
