require "./app/presenters/submissions/edit_presenter"
require_relative "showing_a_submission_spec"

describe Submissions::EditPresenter do
  let(:assignment) { double(:assignment) }
  before { allow(subject).to receive(:assignment).and_return assignment }

  it_behaves_like "showing a submission"

  describe "#initialize" do
    it "allows a submission to be set" do
      submission = double(:submission)
      subject = described_class.new submission: submission
      expect(subject.submission).to eq submission
    end
  end

  describe "#title" do
    let(:user) { double(:user, is_student?: false) }
    let(:view_context) { double(:view_context, current_user: user) }
    before { allow(subject).to receive(:view_context).and_return view_context }

    it "contains the group name if the assignment has a group" do
      group = double(:group, name: "Cool kids")
      allow(assignment).to receive(:has_groups?).and_return true
      allow(subject).to receive(:group).and_return group
      expect(subject.title).to eq "Editing Cool kids's Submission"
    end

    it "contains the students name if the current user is staff" do
      student = double(:user, name: "Jimmy Page")
      submission = double(:submission, student: student)
      allow(subject).to receive(:submission).and_return submission
      allow(assignment).to receive(:has_groups?).and_return false
      expect(subject.title).to eq "Editing Jimmy Page's Submission"
    end

    it "contains the assignment name if the current user is a student" do
      allow(user).to receive(:is_student?).and_return true
      allow(assignment).to receive(:name).and_return "Big assignment"
      expect(subject.title).to eq "Editing My Submission for Big assignment"
    end
  end
end
