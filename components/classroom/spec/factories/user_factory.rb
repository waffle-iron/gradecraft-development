FactoryGirl.define do
  factory :user, class: Classroom::User do
    email { Faker::Internet.email }
    username { Faker::Internet.user_name }
  end
end
