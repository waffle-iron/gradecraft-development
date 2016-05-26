require "active_record_spec_helper"
require "cancan/matchers"

describe Ability do
  let(:course) { student_course_membership.course }
  let(:student_course_membership) { create :student_course_membership }
  let(:student) { student_course_membership.user }

  subject { described_class.new(student, course) }

  context "for a Submission" do
    let(:assignment) { create(:assignment, course: course, grade_scope: "Individual") }
    let(:submission) { build :submission, assignment: assignment, course: course, student: student }

    it "is viewable by the student who the submission is from" do
      expect(subject).to be_able_to(:read, submission)
    end

    it "is not viewable by other students" do
      someone_else = create :user
      subject = described_class.new(someone_else, course)
      expect(subject).to_not be_able_to(:read, submission)
    end

    it "is viewable for the group of students" do
      assignment = create(:assignment, grade_scope: "Group")
      group = create :group
      group.students << student
      assignment.groups << group
      submission.assignment = assignment
      submission.group = group
      submission.student_id = nil
      expect(subject).to be_able_to(:read, submission)
    end

    it "is not viewable for students outside the group" do
      assignment = create(:assignment, grade_scope: "Group")
      group = create :group
      assignment.groups << group
      submission.assignment = assignment
      submission.group = group
      submission.student_id = nil
      expect(subject).to_not be_able_to(:read, submission)
    end

    it "is viewable by an instructor in the course" do
      professor_course_membership = create :professor_course_membership,
        course: course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to be_able_to(:read, submission)
    end

    it "is not viewable by an instructor in another course" do
      another_course = create :course
      professor_course_membership = create :professor_course_membership,
        course: another_course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to_not be_able_to(:read, submission)
    end
  end
end
