require "spec_helper"
require "./app/presenters/submissions/presenter"

describe Submissions::Presenter do
  let(:assignment_id) { 123 }
  let(:course) { double(:course) }
  subject { described_class.new assignment_id: assignment_id, course: course }

  describe "#assignment" do
    it "returns the assignment from the id passed in as a property" do
      assignment = double(:assignment)
      assignments = double(:active_record_relation)
      allow(assignments).to receive(:find).with(123).and_return assignment
      allow(course).to receive(:assignments).and_return assignments
      expect(subject.assignment).to eq assignment
    end
  end

  describe "#course" do
    it "is the course that is passed in as a property" do
      expect(subject.course).to eq course
    end
  end

  describe "#group" do
    let(:assignment) { double(:assignment, has_groups?: true) }
    let(:group_id) { 765 }
    subject { described_class.new group_id: group_id, course: course }

    before { allow(subject).to receive(:assignment).and_return assignment }

    it "is nil if the assignment does not allow groups" do
      allow(assignment).to receive(:has_groups?).and_return false
      expect(subject.group).to eq nil
    end

    it "returns the group from the group id that was passed in as a property" do
      group = double(:group)
      groups = double(:active_record_relation)
      allow(groups).to receive(:find).with(group_id).and_return group
      allow(course).to receive(:groups).and_return groups
      expect(subject.group).to eq group
    end
  end
end
