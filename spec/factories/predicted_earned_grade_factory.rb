FactoryGirl.define do
  factory :predicted_earned_grade do
    association :assignment
    association :student, factory: :user
    predicted_points { rand(assignment.point_total) }
  end
end
