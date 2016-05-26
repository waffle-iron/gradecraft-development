FactoryGirl.define do
  factory :predicted_earned_badge do
    association :badge
    association :student, factory: :user
    predicted_times_earned { rand(3) }
  end
end
