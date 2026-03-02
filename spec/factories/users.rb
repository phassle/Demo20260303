FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    role { "manager" }

    trait :technician do
      role { "technician" }
    end

    trait :admin do
      role { "admin" }
    end
  end
end
