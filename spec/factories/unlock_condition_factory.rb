FactoryGirl.define do
  factory :unlock_condition do
    association :unlockable, factory: :badge
    unlockable_type "Badge"
    association :condition, factory: :assignment
    condition_type "Assignment"
    condition_state "Earned"
  end
end
