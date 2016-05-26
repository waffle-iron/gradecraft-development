require "active_record_spec_helper"
require "cancan/matchers"

describe Ability do
  let(:course) { student_course_membership.course }
  let(:student_course_membership) { create :student_course_membership }
  let(:student) { student_course_membership.user }

  subject { described_class.new(student, course) }

  context "for a Grade" do
    it "can read a grade if the GradeProctor says it can" do
      allow_any_instance_of(GradeProctor).to  \
        receive(:viewable?).with(user: student, course: course).and_return true

      expect(subject).to be_able_to(:read, Grade.new)
    end

    it "can't read a grade if the GradeProctor says it can't" do
      allow_any_instance_of(GradeProctor).to  \
        receive(:viewable?).with(user: student, course: course).and_return false

      expect(subject).to_not be_able_to(:read, Grade.new)
    end

    it "can update a grade if the GradeProctor says it can" do
      allow_any_instance_of(GradeProctor).to  \
        receive(:updatable?).with(user: student, course: course).and_return true

      expect(subject).to be_able_to(:update, Grade.new)
    end

    it "passes on the options to the GradeProctor on update" do
      expect_any_instance_of(GradeProctor).to  \
        receive(:updatable?).with(user: student, course: course,
                                  student_logged: false).and_return true

      expect(subject).to be_able_to(:update, Grade.new, student_logged: false)
    end

    it "can destroy a grade if the GradeProctor says it can" do
      allow_any_instance_of(GradeProctor).to  \
        receive(:destroyable?).with(user: student, course: course).and_return true

      expect(subject).to be_able_to(:destroy, Grade.new)
    end
  end
end
