FactoryGirl.define do
  factory :user, class: Classroom::User do
    email { Faker::Internet.email }
  end
end
