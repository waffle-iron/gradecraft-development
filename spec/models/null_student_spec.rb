require "active_record_spec_helper"

describe NullStudent do

  describe "NullStudent" do
    it "has a course, grades attr accessor" do
      course = Course.new
      student = NullStudent.new(course)
      expect(student.course).to eq(course)
      expect(student.grades.class).to eq(NullStudentGrades)
    end

    it "has an id" do
      student = NullStudent.new
      expect(student.id).to eq(0)
    end

    it "returns false for submissions" do
      student = NullStudent.new
      expect(student.submission_for_assignment(0).present?).to eq(false)
    end

    it "returns false for checking if staff" do
      expect(NullStudent.new).to_not be_is_staff double(:course)
    end

    it "handles student weights" do
      student = NullStudent.new
      expect(student.weight_for_assignment_type).to eq(0)
    end
  end

  describe "NullStudent has NullStudentGrades" do
    it "handles student.grades.where(...).select(...)" do
      student = NullStudent.new
      expect(student.grades.where(course_id: 5).select(:score).class).to eq(NullStudentGrades)
    end

    it "handles student.grades.first" do
      student = NullStudent.new
      expect(student.grades.first.class).to eq(NullGrade)
    end
  end

  describe "NullStudentTeam and it's grades" do
    it "returns true for team for course present?" do
      student = NullStudent.new
      expect(student.team_for_course(0).present?).to eq(true)
    end

    it "returns a team id" do
      team = NullTeam.new
      expect(team.id).to eq(0)
      expect(team.challenge_grades.first.challenge_id).to eq(0)
    end

    it "return null grades for team" do
      team = NullTeam.new
      expect(team.challenge_grades.class).to eq(NullStudentGrades)
    end
  end
end


