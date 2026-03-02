FactoryBot.define do
  factory :property do
    name { "#{Faker::Address.community} #{rand(1..50)}" }
    address { Faker::Address.street_address }
    city { ["Stockholm", "Göteborg", "Malmö", "Uppsala"].sample }
    property_type { "residential" }
    units_count { rand(1..100) }
  end
end
