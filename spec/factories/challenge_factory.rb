FactoryGirl.define do
  factory :challenge do
    association :course
    name { Faker::Lorem.word }
    release_necessary false
    point_total { rand(200) + 100 }
  end
end
