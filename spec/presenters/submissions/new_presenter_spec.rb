require "active_support/inflector"
require "spec_helper"
require "./app/presenters/submissions/new_presenter"

describe Submissions::NewPresenter do
  let(:assignment) { double(:assignment) }

  before { allow(subject).to receive(:assignment).and_return assignment }

  describe "#initialize" do
    it "allows a submission to be set" do
      submission = double(:submission)
      subject = described_class.new submission: submission
      expect(subject.submission).to eq submission
    end

    it "allows a student to be set" do
      student = double(:student)
      subject = described_class.new student: student
      expect(subject.student).to eq student
    end
  end

  describe "#submission" do
    it "returns a new submission from the assignment" do
      submission = double(:submission)
      submissions = double(:active_record_relation, new: submission)
      allow(assignment).to receive(:submissions).and_return submissions
      expect(subject.submission).to eq submission
    end
  end

  describe "#student" do
    let(:student) { double(:user) }
    let(:view_context) { double(:view_context, current_student: student) }
    subject { described_class.new view_context: view_context }

    it "returns the current student from the view context" do
      expect(subject.student).to eq student
    end
  end

  describe "#title" do
    it "contains the assignment name and point total" do
      view_context = double(:view_context, points: "10,000")
      allow(subject).to receive(:view_context).and_return view_context
      allow(assignment).to receive_messages name: "Fun Assignment", point_total: 10000
      expect(subject.title).to eq "Submit Fun Assignment (10,000 points)"
    end
  end
end
