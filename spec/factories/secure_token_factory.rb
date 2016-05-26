FactoryGirl.define do
  factory :secure_token do
    association :target, factory: :submissions_export
  end
end

