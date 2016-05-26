require "active_record_spec_helper"
require "cancan/matchers"

describe Ability do
  let(:course) { student_course_membership.course }
  let(:student_course_membership) { create :student_course_membership }
  let(:student) { student_course_membership.user }

  subject { described_class.new(student, course) }

  context "for an Assignment Weight" do
    let(:assignment_weight) { build :assignment_weight, course: course, student: student }

    it "is viewable by the student who the assignment weight is for" do
      expect(subject).to be_able_to(:read, assignment_weight)
    end

    it "is not viewable by another student" do
      course_membership = create :student_course_membership, course: course
      subject = described_class.new course_membership.user, course
      expect(subject).to_not be_able_to(:read, assignment_weight)
    end

    it "is not viewable from another course" do
      course = create :course
      subject = described_class.new student, course
      expect(subject).to_not be_able_to(:read, assignment_weight)
    end

    it "is viewable by an instructor in the course" do
      professor_course_membership = create :professor_course_membership,
        course: course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to be_able_to(:read, assignment_weight)
    end

    it "is not viewable by an instructor in another course" do
      another_course = create :course
      professor_course_membership = create :professor_course_membership,
        course: another_course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to_not be_able_to(:read, assignment_weight)
    end
  end
end
