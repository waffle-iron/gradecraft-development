require "active_record_spec_helper"
require "cancan/matchers"

describe Ability do
  let(:course) { student_course_membership.course }
  let(:student_course_membership) { create :student_course_membership }
  let(:student) { student_course_membership.user }

  subject { described_class.new(student, course) }

  context "for an Announcement" do
    let(:announcement) { build :announcement, course: course }

    it "is viewable by any user associated the course" do
      expect(subject).to be_able_to(:read, announcement)
    end

    it "is creatable by any staff for the course" do
      professor_course_membership = create :professor_course_membership,
        course: course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to be_able_to(:create, announcement)
    end

    it "is not creatable by a student" do
      expect(subject).to_not be_able_to(:create, announcement)
    end

    it "is not creatable by an instructor in another course" do
      course = create :course
      professor_course_membership = create :professor_course_membership,
        course: course
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to_not be_able_to(:create, announcement)
    end

    it "is updatable by the author" do
      professor_course_membership = create :professor_course_membership,
        course: course
      announcement.author_id =  professor_course_membership.user_id
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to be_able_to(:update, announcement)
    end

    it "is destroyable by the author" do
      professor_course_membership = create :professor_course_membership,
        course: course
      announcement.author_id =  professor_course_membership.user_id
      subject = described_class.new(professor_course_membership.user, course)
      expect(subject).to be_able_to(:destroy, announcement)
    end
  end
end
