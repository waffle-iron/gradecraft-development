require "active_record_spec_helper"

describe PredictedEarnedGrade do

  before do
    @predicted_earned_challenge = create(:predicted_earned_challenge)
  end

  subject { @predicted_earned_challenge }

  it { is_expected.to respond_to("student_id")}
  it { is_expected.to respond_to("challenge_id")}
  it { is_expected.to respond_to("predicted_points")}

  it { is_expected.to be_valid }

  describe ".for_course" do
    it "returns all predicted earned challenges for a specific course" do
      course = create(:course)
      course_predicted_challenge = create(:predicted_earned_challenge,
                                    challenge: create(:challenge, course: course))
      another_predicted_challenge = create(:predicted_earned_challenge)
      results = PredictedEarnedChallenge.for_course(course)
      expect(results).to eq [course_predicted_challenge]
    end
  end

  describe ".for_student" do
    it "returns all predicted earned challenges for a specific student" do
      student = create(:user)
      student_predicted_challenge = create(:predicted_earned_challenge,
                                           student: student)
      another_predicted_challenge = create(:predicted_earned_challenge)
      results = PredictedEarnedChallenge.for_student(student)
      expect(results).to eq [student_predicted_challenge]
    end
  end
end
