FactoryGirl.define do
  factory :rubric do
    association :assignment

    factory :rubric_with_criteria do
      after(:create) do |rubric|
        (0..5).each {|i| create(:criterion_with_level_and_grade, rubric: rubric, order: i)}
      end
    end
  end
end
