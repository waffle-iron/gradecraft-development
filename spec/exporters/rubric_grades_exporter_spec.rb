require "active_record_spec_helper"
require "./app/exporters/criterion_grades_exporter"

describe CriterionGradesExporter do
  let(:course) { create :course }
  let(:assignment) { create :assignment, course: course }
  let(:rubric) { create :rubric_with_criteria, assignment: assignment }
  let(:student) { create :user}

  subject { CriterionGradesExporter.new }

  describe "#export" do
    it "generates a CSV with base student columns" do
      csv = subject.export(course, rubric)
      expect(csv).to include "First Name", "Last Name", "Email", "Username", "Team"
    end

    it "generates a CSV with student criterion grades" do
      student.courses << course
      course.students.each do |student|
        rubric.criteria.each do |criterion|
          level = Level.create(criterion_id: criterion.id, name: "Sushi Success", points: 2000)
          CriterionGrade.create(criterion: criterion, level_id: level.id, student: student, points: 2000, assignment: assignment)
        end
      end

      csv = CSV.new(subject.export(course, rubric)).read
      expect(csv.length).to eq 2
      expect(csv[1][0]).to eq course.students.first.first_name
      expect(csv[1][1]).to eq course.students.first.last_name
      expect(csv[1][2]).to eq course.students.first.email
      expect(csv[1][3]).to eq course.students.first.username
      expect(csv[1][4]).to eq course.students.first.team_for_course(course)
      expect(csv[1][5]).to eq "Sushi Success: "
    end
  end
end
