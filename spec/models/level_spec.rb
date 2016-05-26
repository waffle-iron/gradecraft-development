require "rails_spec_helper"

describe Level do
  describe "#copy" do
    let(:level) { create :level }
    subject { level }

    describe "#above_expectations?" do
      it "is false if points are equal to or below expectations" do
        subject.criterion.update(meets_expectations_points: subject.points)
        expect(subject.above_expectations?).to be_falsey
      end

      it "is true if points are above expectations" do
        allow(subject.criterion).to \
          receive(:meets_expectations_level_id).and_return("not nil")
        subject.criterion.update(
          meets_expectations_points: (subject.points - 1)
        )
        expect(subject.above_expectations?).to be_truthy
      end
    end

    describe "#copy" do
      subject { level.copy }

      it "copies the badges for the levels" do
        level.save
        level.badges.create! name: "Blah", course: create(:course)
        expect(subject.badges.size).to eq 1
        expect(subject.level_badges.map(&:level_id)).to eq [subject.id]
      end
    end

    describe "updating points" do
      it "updates the meets exectations points on criterion" do
        level.save
        level.criterion.update_meets_expectations!(level, true)
        level.update(points: 10)
        expect(level.criterion.reload.meets_expectations_points).to eq(10)
      end
    end
  end

  describe "#earned_by?" do
    let!(:criterion_grade) { create :criterion_grade, level: subject,
                             student: student }
    let(:student) { create :user }
    subject { create :level }

    it "is earned if a criterion grade exists for the student" do
      expect(subject).to be_earned_for student.id
    end

    it "is not earned if a criterion grade does not exist for the student" do
      expect(subject).to_not be_earned_for 12345
    end
  end

  describe "#hide_analytics?" do
    let(:criterion) { build :criterion, rubric: rubric }
    let(:rubric) { build :rubric }
    subject { build :level, criterion: criterion }

    it "is hidden if the course and assignment are set to hide analytics" do
      rubric.assignment.hide_analytics = true
      rubric.assignment.course.hide_analytics = true
      expect(subject.hide_analytics?).to eq true
    end

    it "is not hidden if the course is not set to hide analytics" do
      rubric.assignment.hide_analytics = true
      rubric.assignment.course.hide_analytics = false
      expect(subject.hide_analytics?).to eq false
    end

    it "is not hidden if the assignment is not set to hide analytics" do
      rubric.assignment.hide_analytics = false
      rubric.assignment.course.hide_analytics = true
      expect(subject.hide_analytics?).to eq false
    end
  end
end
