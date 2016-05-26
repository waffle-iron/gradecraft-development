require "rspec/core"
require "./app/presenters/assignments/group_presenter"

describe Assignments::GroupPresenter do
  let(:assignment) { double(:assignment) }
  let(:group) { double(:group, name: "My Group") }
  let(:submission) { double(:submission) }
  subject { Assignments::GroupPresenter.new({ assignment: assignment, group: group })}

  describe "#assignment_graded?" do
    it "has been graded if it has been graded for any user in the group" do
      student = double(:user, grade_for_assignment: double(:grade, is_graded?: true))
      allow(group).to receive(:students).and_return [student]
      expect(subject.assignment_graded?).to eq true
    end
  end

  describe "#grade_for" do
    it "returns the grade for the specified student" do
      grade = double(:grade)
      grades= double(:relation, find_by: grade)
      allow(assignment).to receive(:grades).and_return grades
      expect(subject.grade_for(double(:user, id: 123))).to eq grade
    end
  end

  describe "#has_submission?" do
    it "has a submission if one is returned for the assignment" do
      allow(group).to receive(:submission_for_assignment).and_return submission
      expect(subject).to have_submission
    end
  end

  describe "#submission" do
    it "returns the submission for the assignment" do
      allow(group).to receive(:submission_for_assignment).and_return submission
      expect(subject.submission).to eq submission
    end
  end

  describe "#students" do
    it "returns the students for the group" do
      student = double(:user, grade_for_assignment: double(:grade, is_graded?: true))
      allow(group).to receive(:students).and_return [student]
      expect(subject.students).to eq ([student])
    end
  end

  describe "#title" do
    it "has the group name" do
      expect(subject.title).to eq "My Group Grades"
    end
  end
end
