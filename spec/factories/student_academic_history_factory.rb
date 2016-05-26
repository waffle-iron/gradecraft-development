FactoryGirl.define do
  factory :student_academic_history do 
    association :student
    association :course
    major { Faker::Commerce.department }
    gpa { Faker::Number.decimal(2)}
    current_term_credits { Faker::Number.between(1, 16) }
    accumulated_credits { Faker::Number.between(0, 80) }
    state_of_residence { Faker::Address.state }
    high_school { Faker::Company.name }
    athlete false
    act_score { Faker::Number.between(10, 32) }
    sat_score { Faker::Number.between(800, 1600) }
  end
end
