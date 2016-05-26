require "active_record_spec_helper"
require "./app/exporters/grades_for_research_exporter"

describe GradesForResearchExporter do
  let(:course) { create :course }
  subject { GradesForResearchExporter.new }

  describe "#export" do
    it "generates an empty CSV if there are no students or assignments" do
      csv = subject.research_grades(course)
      expect(csv).to eq "Course ID,Uniqname,First Name,Last Name,GradeCraft ID,Assignment Name,Assignment ID,Assignment Type,Assignment Type Id,Score,Assignment Point Total,Multiplied Score,Predicted Score,Text Feedback,Submission ID,Submission Creation Date,Submission Updated Date,Graded By,Created At,Updated At\n"
    end

    it "generates a CSV with student grades for the course" do
      @student = create(:user)
      @student.courses << course
      @assignment_type = create(:assignment_type, course: course)
      @assignment = create(:assignment, course: course, assignment_type: @assignment_type, name: "Quiz")
      @grade = create(:grade, raw_score: 100, course: course, student: @student, assignment: @assignment)
      @predicted_earned_grade = create(:predicted_earned_grade, assignment: @assignment, student: @student)
      graded_at = DateTime.now
      allow_any_instance_of(Grade).to receive(:graded_at).and_return graded_at

      csv = CSV.new(subject.research_grades(course)).read
      expect(csv.length).to eq 2
      expect(csv[1][0]).to eq "#{course.id}"
      expect(csv[1][1]).to eq @student.username
      expect(csv[1][2]).to eq @student.first_name
      expect(csv[1][3]).to eq @student.last_name
      expect(csv[1][4]).to eq "#{@student.id}"
      expect(csv[1][5]).to eq "Quiz"
      expect(csv[1][6]).to eq "#{@assignment.id}"
      expect(csv[1][7]).to eq @assignment_type.name
      expect(csv[1][8]).to eq "#{@assignment_type.id}"
      expect(csv[1][9]).to eq "#{@grade.raw_score}"
      expect(csv[1][10]).to eq "#{@grade.point_total}"
      expect(csv[1][11]).to eq "#{@grade.score}"
      expect(csv[1][12]).to eq "#{@predicted_earned_grade.predicted_points}"
      expect(csv[1][13]).to eq "#{@grade.feedback}"
      expect(csv[1][14]).to eq "#{@grade.submission_id}"
      expect(csv[1][15]).to eq "#{@grade.submission.try(:created_at)}"
      expect(csv[1][16]).to eq "#{@grade.submission.try(:updated_at)}"
      expect(csv[1][17]).to eq "#{@grade.graded_by_id}"
      expect(csv[1][18]).to eq "#{@grade.created_at}"
      expect(csv[1][19]).to eq "#{graded_at}"
    end
  end
end
