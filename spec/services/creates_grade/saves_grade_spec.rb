require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_grade/saves_grade"

describe Services::Actions::SavesGrade do
  let(:grade) { build :grade }

  it "expects grade passed to service" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "saves the grades" do
    result = described_class.execute grade: grade
    expect(result[:grade]).to_not be_new_record
  end

  it "promises the student visible status" do
    result = described_class.execute grade: grade
    expect(result).to have_key :student_visible_status
  end

  it "halts if a record is invalid" do
    grade.student_id = nil
    expect { described_class.execute grade: grade }.to \
      raise_error LightService::FailWithRollbackError
  end

  it "sets the student visible status to nil when grade not visible" do
    result = described_class.execute grade: grade
    expect(result[:student_visible_status]).to be_falsey
  end

  it "sets the student visible status to true when grade is visible" do
    allow_any_instance_of(GradeProctor).to \
              receive(:viewable?).and_return true
    result = described_class.execute grade: grade
    expect(result[:student_visible_status]).to be_truthy
  end
end
