require "active_record_spec_helper"
require "./app/services/creates_grade_using_rubric"

describe Services::CreatesGradeUsingRubric do
  let(:params) { RubricGradePUT.new.params }
  let(:user) { create :user }

  describe ".create" do
    it "confirms the student and assignment" do
      expect(Services::Actions::VerifiesAssignmentStudent).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "initializes new criterion grades" do
      expect(Services::Actions::BuildsCriterionGrades).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "saves criterion grades" do
      expect(Services::Actions::SavesCriterionGrades).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "initializes new grade from params" do
      expect(Services::Actions::BuildsGrade).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "adds the submission id to the grade" do
      expect(Services::Actions::AssociatesSubmissionWithGrade).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "marks grade as graded" do
      expect(Services::Actions::MarksAsGraded).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "saves the grade" do
      expect(Services::Actions::SavesGrade).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "creates level badges" do
      expect(Services::Actions::BuildsEarnedLevelBadges).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "saves level badges" do
      expect(Services::Actions::SavesEarnedLevelBadges).to receive(:execute).and_call_original
      described_class.create params, user
    end

    it "runs the grade updater job" do
      expect(Services::Actions::RunsGradeUpdaterJob).to receive(:execute).and_call_original
      described_class.create params, user
    end
  end
end
