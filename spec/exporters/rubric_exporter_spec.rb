require "active_record_spec_helper"
require "./app/exporters/rubric_exporter"

describe RubricExporter do
  let(:course) { create :course }
  let(:assignment) { create :assignment, course: course }
  let(:rubric) { create :rubric_with_criteria, assignment: assignment }
  subject { RubricExporter.new }

  describe "#export" do
    it "generates a CSV with criteria" do
      csv = CSV.new(subject.export(rubric)).read
      expect(csv.length).to eq 7
      expect(csv[1][0]).to eq "#{rubric.criteria.first.id}"
      expect(csv[2][0]).to eq "#{rubric.criteria.second.id}"
      expect(csv[1][1]).to eq rubric.criteria.first.name
      expect(csv[2][1]).to eq rubric.criteria.second.name
    end
  end
end
