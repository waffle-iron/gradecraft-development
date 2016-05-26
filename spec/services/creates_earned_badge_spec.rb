require "active_record_spec_helper"
require "./app/services/creates_earned_badge"

describe Services::CreatesEarnedBadge do
  describe ".award" do
    let(:world) { World.create.with(:course, :assignment, :student, :badge, :grade) }

    let(:attributes) do
      {
        student_id: world.student.id,
        badge_id: world.badge.id,
        assignment_id: world.assignment.id,
        grade_id: world.grade.id,
        score: 800,
        student_visible: true,
        feedback: "You are so awesome!"
      }
    end

    before do
      class FakeJob
        def initialize(attributes); end
        def enqueue; end
      end

      stub_const("ScoreRecalculatorJob", FakeJob)
    end

    it "creates a new earned badge" do
      expect(Services::Actions::CreatesEarnedBadge).to \
        receive(:execute).and_call_original
      described_class.award attributes
    end

    it "recalculates the student's score" do
      expect(Services::Actions::RecalculatesStudentScore).to \
        receive(:execute).and_call_original
      described_class.award attributes
    end

    it "notifies the student of the awarded badge" do
      expect(Services::Actions::NotifiesOfEarnedBadge).to \
        receive(:execute).and_call_original
      described_class.award attributes
    end
  end
end
