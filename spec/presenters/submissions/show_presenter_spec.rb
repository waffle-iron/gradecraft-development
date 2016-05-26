require "active_support/inflector"
require "./app/presenters/submissions/show_presenter"
require_relative "showing_a_submission_spec"

describe Submissions::ShowPresenter do
  let(:assignment) { double(:assignment, point_total: 12000) }
  let(:student) { double(:user, first_name: "Jimmy") }
  let(:group) { double(:group, name: "My group") }
  let(:submission) { double(:submission, student: student, group: group) }

  it_behaves_like "showing a submission"

  describe "#title" do
    let(:view_context) { double(:view_context, points: "12,000") }

    before do
      allow(subject).to receive(:assignment).and_return assignment
      allow(subject).to receive_messages submission: submission, view_context: view_context
    end

    it "includes the individual's name for a student" do
      allow(assignment).to receive_messages name: "New Assignment", is_individual?: true
      expect(subject.title).to eq "Jimmy's New Assignment Submission (12,000 points)"
    end

    it "includes the groups's name for a group" do
      allow(assignment).to receive_messages name: "New Assignment", is_individual?: false, has_groups?: true
      expect(subject.title).to eq "My group's New Assignment Submission (12,000 points)"
    end
  end
end
