require "active_record_spec_helper"
require "./app/exporters/grade_exporter"

describe GradeExporter do
  let(:assignment) { create(:assignment) }
  let(:students) { create_list :user, 2 }
  subject { GradeExporter.new }

  describe "#export_grades" do
    it "generates an empty CSV if there is no assignment specified" do
      csv = subject.export_grades(nil, [])
      expect(csv).to eq "First Name,Last Name,Email,Score,Feedback\n"
    end

    it "generates an empty CSV if there are no students specified" do
      csv = subject.export_grades(assignment, [])
      expect(csv).to eq "First Name,Last Name,Email,Score,Feedback\n"
    end

    it "generates a CSV with student scores" do
      allow(students[0]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return double(:grade, score: 123, feedback: nil)
      allow(students[1]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return double(:grade, score: 456, feedback: "Grrrrreat!")

      csv = CSV.new(subject.export_grades(assignment, students)).read
      expect(csv.length).to eq 3
      expect(csv[1][0]).to eq students[0].first_name
      expect(csv[2][0]).to eq students[1].first_name
      expect(csv[1][1]).to eq students[0].last_name
      expect(csv[2][1]).to eq students[1].last_name
      expect(csv[1][2]).to eq students[0].email
      expect(csv[2][2]).to eq students[1].email
      expect(csv[1][3]).to eq "123"
      expect(csv[2][3]).to eq "456"
      expect(csv[1][4]).to eq ""
      expect(csv[2][4]).to eq "Grrrrreat!"
    end

    it "includes students that do not have grades for the assignment" do
      allow(students[0]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return nil
      csv = CSV.new(subject.export_grades(assignment, students)).read
      expect(csv[1][3]).to eq ""
    end
  end

  describe "#export_grades_with_detail" do
    it "generates an empty CSV if there is no assignment specified" do
      csv = subject.export_grades_with_detail(nil, [])
      expect(csv).to eq "First Name,Last Name,Email,Score,Feedback,Raw Score,Statement,Last Updated\n"
    end

    it "generates an empty CSV if there are no students specified" do
      csv = subject.export_grades_with_detail(assignment, [])
      expect(csv).to eq "First Name,Last Name,Email,Score,Feedback,Raw Score,Statement,Last Updated\n"
    end

    it "generates a CSV with student grades for the assignment" do
      updated_at = DateTime.now
      allow(students[0]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return double(:grade, graded_or_released?: false, score: 123,
                             raw_points: 789, feedback: nil, graded_at: updated_at)
      allow(students[1]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return double :grade, graded_or_released?: true, score: 456,
                             raw_points: 456, feedback: "Grrrrreat!", graded_at: updated_at
      allow(students[1]).to \
        receive(:submission_for_assignment).with(assignment)
          .and_return double(:submission, text_comment: "Hello there")

      csv = CSV.new(subject.export_grades_with_detail(assignment, students)).read
      expect(csv.length).to eq 3
      expect(csv[1][0]).to eq students[0].first_name
      expect(csv[2][0]).to eq students[1].first_name
      expect(csv[1][1]).to eq students[0].last_name
      expect(csv[2][1]).to eq students[1].last_name
      expect(csv[1][2]).to eq students[0].email
      expect(csv[2][2]).to eq students[1].email
      expect(csv[1][3]).to eq "123"
      expect(csv[2][3]).to eq "456"
      expect(csv[1][4]).to eq ""
      expect(csv[2][4]).to eq "Grrrrreat!"
      expect(csv[1][5]).to eq "789"
      expect(csv[2][5]).to eq "456"
      expect(csv[1][6]).to eq ""
      expect(csv[2][6]).to eq "Hello there"
      expect(csv[1][7]).to eq "#{updated_at}"
      expect(csv[2][7]).to eq "#{updated_at}"
    end

    it "includes students that do not have grades for the assignment" do
      allow(students[0]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return nil
      csv = CSV.new(subject.export_grades_with_detail(assignment, students)).read
      expect(csv[1][3]).to eq ""
    end

    it "does not include the grade if it has not been graded or released" do
      allow(students[0]).to \
        receive(:grade_for_assignment).with(assignment)
          .and_return double(:grade, graded_or_released?: false)
      csv = CSV.new(subject.export_grades_with_detail(assignment, students)).read
      expect(csv[1][3]).to eq ""
    end
  end
end
