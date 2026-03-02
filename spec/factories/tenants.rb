FactoryBot.define do
  factory :tenant do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    phone { Faker::PhoneNumber.phone_number }
    property
    unit_number { "#{rand(1..10)}#{("A".."D").to_a.sample}" }
    lease_start { 1.year.ago }
    lease_end { 1.year.from_now }
  end
end
