FactoryGirl.define do
  factory :challenge_grade do
    association :challenge
    association :team

    factory :released_challenge_grade do
      association :challenge, release_necessary: true
      association :team
      score { Faker::Number.number(5) }
      status "Released"
    end

    factory :graded_challenge_grade do
      association :challenge
      association :team
      score { rand(challenge.full_points) }
      status "Graded"
    end

    factory :grades_not_released_challenge_grade do
      association :challenge, release_necessary: true
      association :team
      score { rand(challenge.full_points) }
      status "Graded"
    end
  end
end
