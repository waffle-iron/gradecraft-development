require "spec_helper"
require "./app/serializers/predicted_grade_serializer"
require "./app/models/null_grade"
require "./app/models/null_student"
require "./lib/grade_proctor"

describe PredictedGradeSerializer do
  let(:course) { double(:course) }
  let(:assignment) { double(:assignment, accepts_submissions?: true, submissions_have_closed?: true )}
  let(:grade) do
    double(
      :grade, id: 123, pass_fail_status: :pass,
      score: 78, final_points: 84, excluded_from_course_score?: false,
      student: user, course: course, assignment: assignment
    )
  end
  let(:user) { double(:user, submission_for_assignment: "sumbission") }

  subject { described_class.new assignment, grade, user }

  before { allow_any_instance_of(GradeProctor).to receive(:viewable?).and_return true }

  describe "#pass_fail_status" do
    it "returns the grade's pass fail status if it's visible" do
      expect(subject.pass_fail_status).to eq grade.pass_fail_status
    end

    it "returns nil if it's not visible" do
      allow_any_instance_of(GradeProctor).to receive(:viewable?).and_return false
      expect(subject.pass_fail_status).to be_nil
    end
  end

  describe "#attributes" do
    it "returns a hash of grade attributes overriden by Class methods" do
      expect(subject.attributes).to eq({
        id: grade.id,
        score: 78,
        final_points: 84,
        is_excluded: grade.excluded_from_course_score?
      })
    end

    describe "final_points" do
      it "returns the grade's final score if it's visible" do
        expect(subject.attributes[:final_points]).to eq grade.final_points
      end

      it "returns nil if it's not visible" do
        allow_any_instance_of(GradeProctor).to receive(:viewable?).and_return false
        expect(subject.attributes[:final_points]).to be_nil
      end

      it "returns 0 with no final score and no sumbission if the assignment submissions have closed" do
        allow(grade).to receive(:final_points).and_return nil
        allow(user).to receive(:submission_for_assignment).and_return nil
        expect(subject.attributes[:final_points]).to eq(0)
      end

      it "doesn't override the final score if present regardless of submission status" do
        allow(user).to receive(:submission_for_assignment).and_return nil
        expect(subject.attributes[:final_points]).to eq(grade.final_points)
      end

      it "always returns 0 for Null Student if the assignment sumbission has closed" do
        expect(described_class.new(assignment, NullGrade.new, NullStudent.new).attributes[:final_points]).to eq(0)
      end
    end

    describe "score" do
      it "returns the grade's score if it's visible" do
        expect(subject.attributes[:score]).to eq grade.score
      end

      it "returns nil if it's not visible" do
        allow_any_instance_of(GradeProctor).to receive(:viewable?).and_return false
        expect(subject.attributes[:score]).to be_nil
      end

      it "returns 0 with no score and no sumbission if the assignment submissions have closed" do
        allow(grade).to receive(:score).and_return nil
        allow(user).to receive(:submission_for_assignment).and_return nil
        expect(subject.attributes[:score]).to eq(0)
      end

      it "doesn't override the score is present regardless of submission status" do
        allow(user).to receive(:submission_for_assignment).and_return nil
        expect(subject.attributes[:score]).to eq(grade.score)
      end

      it "always returns 0 for Null Student if the assignment sumbission has closed" do
        expect(described_class.new(assignment, NullGrade.new, NullStudent.new).attributes[:score]).to eq(0)
      end
    end

  end
end
