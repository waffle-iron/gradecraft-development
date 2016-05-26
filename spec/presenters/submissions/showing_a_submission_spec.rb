require "spec_helper"

shared_examples_for "showing a submission" do
  let(:assignment) { double(:assignment) }
  let(:submission_id) { 123 }
  subject { described_class.new id: submission_id }

  before { allow(subject).to receive(:assignment).and_return assignment }

  describe "#submission" do
    it "returns the submission from the assignment based on the id" do
      submission = double(:submission)
      submissions = double(:active_record_relation)
      allow(submissions).to receive(:find).with(submission_id).and_return submission
      allow(assignment).to receive(:submissions).and_return submissions
      expect(subject.submission).to eq submission
    end
  end

  describe "#student" do
    let(:submission) { double(:submission, student: student) }
    let(:student) { double(:user) }

    before { allow(subject).to receive(:submission).and_return submission }

    it "returns the student for the submission" do
      expect(subject.student).to eq student
    end
  end
end
