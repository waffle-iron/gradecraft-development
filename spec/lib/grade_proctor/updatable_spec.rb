require "./lib/grade_proctor"

describe GradeProctor::Updatable do
  let(:assignment) { double(:assignment, student_logged?: false,
                            release_necessary?: true) }
  let(:course) { double(:course, id: 456) }
  let(:grade) { double(:grade, assignment: assignment, course_id: course.id,
                       student_id: 123, student: user, is_graded?: true,
                       is_released?: false) }
  let(:user) { double(:user, id: 123, is_staff?: false) }

  describe "#updatable?" do
    subject { GradeProctor.new(grade) }

    it "cannot be updatable if the grade is nil" do
      subject = GradeProctor.new(nil)
      expect(subject).to_not be_updatable user: user, course: course
    end

    context "as a student" do
      context "with a student logged assignment" do
        before { allow(assignment).to receive(:student_logged?).and_return true }

        it "can update a grade" do
          expect(subject).to be_updatable user: user, course: course
        end

        it "cannot update a grade that does not belong to them" do
          allow(grade).to receive(:student_id).and_return 456
          expect(subject).to_not be_updatable user: user, course: course
        end
      end

      context "without needing to be student logged" do
        it "can update a grade" do
          expect(subject).to be_updatable user: user, course: course,
            student_logged: false
        end

        it "cannot update a grade that does not belong to them" do
          allow(grade).to receive(:student_id).and_return 456
          expect(subject).to_not be_updatable user: user, course: course,
            student_logged: false
        end
      end

      it "cannot update a grade that is updated by an instructor" do
        expect(subject).to_not be_updatable user: user, course: course
      end
    end

    context "as part of the course staff" do
      let(:staff) { double(:user, id: 456, is_staff?: true) }

      it "can update if they are the instructor for the course" do
        expect(subject).to be_updatable user: staff, course: course
      end

      it "cannot update if they are not the instructor for the course" do
        allow(staff).to receive(:is_staff?).with(course).and_return false
        expect(subject).to_not be_updatable user: staff, course: course
      end
    end
  end
end
