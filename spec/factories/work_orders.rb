FactoryBot.define do
  factory :work_order do
    title { "Fix #{["leaking faucet", "broken window", "heating issue", "door lock", "elevator maintenance"].sample}" }
    description { Faker::Lorem.paragraph }
    status { "open" }
    priority { "normal" }
    property

    trait :urgent do
      priority { "urgent" }
    end

    trait :unassigned do
      assigned_to { nil }
    end

    trait :old do
      created_at { 20.days.ago }
    end
  end
end
