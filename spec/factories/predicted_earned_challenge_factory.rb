FactoryGirl.define do
  factory :predicted_earned_challenge do
    association :challenge
    association :student, factory: :user
    predicted_points { rand(challenge.point_total) }
  end
end
