require "./lib/grade_proctor"

describe GradeProctor::Viewable do
  let(:assignment) { double(:assignment, release_necessary?: true) }
  let(:course) { double(:course, id: 456) }
  let(:grade) { double(:grade, assignment: assignment, course_id: course.id,
                       student_id: 123, is_graded?: true, is_released?: false) }
  let(:user) { double(:user, id: 123, is_staff?: false) }

  describe "#viewable?" do
    subject { GradeProctor.new(grade) }

    it "cannot be viewable if the grade is nil" do
      subject = GradeProctor.new(nil)
      expect(subject).to_not be_viewable user: user, course: course
    end

    context "as a student" do
      it "cannot view the grade if it's not assigned to them" do
        allow(grade).to receive(:student_id).and_return 456
        expect(subject).to_not be_viewable user: user, course: course
      end

      it "cannot view the grade if it's not part of the course" do
        allow(grade).to receive(:is_released?).and_return true
        allow(grade).to receive(:course_id).and_return 789
        expect(subject).to_not be_viewable user: user, course: course
      end

      it "can view the grade if it's been released" do
        allow(grade).to receive(:is_released?).and_return true
        expect(subject).to be_viewable user: user, course: course
      end

      it "can view the grade if it's been graded and a release is not necessary" do
        allow(assignment).to receive(:release_necessary?).and_return false
        expect(subject).to be_viewable user: user, course: course
      end

      it "cannot view the grade if it's been graded and a release is necessary" do
        expect(subject).to_not be_viewable user: user, course: course
      end
    end

    context "as part of the course staff" do
      let(:staff) { double(:user, id: 456, is_staff?: true) }

      it "can view the grade if they are the instructor for the course" do
        expect(subject).to be_viewable user: staff, course: course
      end

      it "cannot view the grade if they are not the instructor for the course" do
        allow(staff).to receive(:is_staff?).with(course).and_return false
        expect(subject).to_not be_viewable user: staff, course: course
      end
    end
  end
end
