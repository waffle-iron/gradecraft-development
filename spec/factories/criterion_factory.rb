FactoryGirl.define do
  factory :criterion do
    max_points { Faker::Number.number(5) }
    name { Faker::Lorem.word }
    sequence(:order)

    factory :criterion_with_level_and_grade do
      after(:create) do |criterion|
        (0..5).each {|i| create(:level, criterion: criterion)}
      end
    end
  end
end
