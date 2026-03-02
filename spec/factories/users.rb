FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    role { 'manager' }
    api_token { SecureRandom.hex(32) }

    trait :technician do
      role { 'technician' }
    end

    trait :admin do
      role { 'admin' }
    end
  end
end
