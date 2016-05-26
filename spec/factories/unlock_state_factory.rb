FactoryGirl.define do
  factory :unlock_state do
    association :unlockable, factory: :badge
    unlockable_type "Badge"
    association :student, factory: :user
    unlocked false
  end
end
