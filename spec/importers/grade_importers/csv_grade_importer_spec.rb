require "active_record_spec_helper"
require "./lib/quote_helper"
require "./app/importers/grade_importers/csv_grade_importer"

describe CSVGradeImporter do
  describe "#import" do
    it "returns empty results when there is no file" do
      result = described_class.new(nil).import
      expect(result.successful).to be_empty
      expect(result.unsuccessful).to be_empty
    end

    context "with a file" do
      let(:assignment) { create :assignment, course: course }
      let(:course) { create :course }
      let(:file) { fixture_file "grades.csv", "text/csv" }
      let!(:user) { create :user }
      subject { described_class.new(file.tempfile) }

      context "with a student not in the file" do
        let(:student) { create :user }
        before do
          create :course_membership, user_id: student.id, course_id: course.id,
              role: "student"
        end

        it "does not create a grade if the student does not exist" do
          expect { subject.import(course, assignment, user) }.to_not change { User.count }
        end

        it "is unsuccessful if the student does not exist" do
          result = subject.import(course, assignment, user)
          expect(result.unsuccessful.count).to eq 3
          expect(result.unsuccessful.first[:errors]).to eq "Student not found in course"
        end
      end

      context "with a student in the file" do
        let(:student) { create :user, email: "robert@example.com" }
        before do
          create :course_membership, user_id: student.id, course_id: course.id,
            role: "student"
        end

        it "creates the grade if it is not there" do
          result = subject.import(course, assignment, user)
          grade = Grade.unscoped.last
          expect(grade.raw_points).to eq 4000
          expect(grade.feedback).to eq "You did great!"
          expect(grade.status).to eq "Graded"
          expect(grade.graded_by_id).to eq user.id
          expect(result.successful.count).to eq 1
          expect(result.successful.last).to eq grade
        end

        it "timestamps the grade" do
          current_time = DateTime.now
          result = subject.import(course, assignment, user)
          grade = Grade.unscoped.last
          expect(grade.graded_at).to be > current_time
        end

        it "updates the grade if it is already there" do
          create :grade, assignment: assignment, student: student, raw_points: 1000
          subject.import(course, assignment, user)
          grade = Grade.last
          expect(grade.raw_points).to eq 4000
          expect(grade.feedback).to eq "You did great!"
          expect(grade.graded_at).to_not be_nil
          expect(grade.graded_by_id).to eq user.id
        end

        it "does not update the grade if the grade and the feedback are the same as the one being imported" do
          grade = create :grade, assignment: assignment, student: student, raw_points: 4000, feedback: "You did great!"
          expect {
            result = subject.import(course, assignment, user)
            expect(result.successful).to be_empty
            expect(result.unchanged.count).to eq 1
            expect(result.unchanged.first).to eq grade
          }.to_not change grade, :updated_at
        end

        it "does not update the grade if it is already there and the score is null" do
          student = create(:user, email: "john@example.com")
          grade = create :grade, assignment: assignment, student: student, raw_points: 4000
          create(:student_course_membership, course: course, user: student)
          result = subject.import(course, assignment, user)
          expect(grade.reload.raw_points).to eq 4000
          expect(grade.graded_at).to be_nil
          expect(result.unsuccessful.last[:errors]).to eq "Grade not specified"
        end

        it "updates the grade if the grade is the same but the feedback is different" do
          grade = create :grade, assignment: assignment, student: student, raw_points: 4000, feedback: "You need some work"
          result = subject.import(course, assignment, user)
          expect(result.successful.count).to eq 1
          expect(result.successful.first).to eq grade
        end

        it "contains an unsuccessful row if the grade is not valid" do
          allow_any_instance_of(Grade).to receive(:valid?).and_return false
          allow_any_instance_of(Grade).to receive(:errors).and_return double(full_messages: ["The grade is not cool"])
          result = subject.import(course, assignment, user)
          expect(result.unsuccessful.count).to eq 3
          expect(result.unsuccessful.first[:errors]).to eq "The grade is not cool"
        end

        it "creates a grade for a student by username" do
          username_student = create :user, username: "jimmy"
          create :course_membership, user_id: username_student.id, course_id: course.id,
            role: "student"
          result = subject.import(course, assignment, user)
          grade = assignment.grades.where(student_id: username_student.id).first
          expect(grade).to_not be_nil
        end
      end
    end
  end
end
