require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_grade/marks_as_graded"

describe Services::Actions::MarksAsGraded do
  let(:grade) { create :grade }
  let(:user) { create :user }

  it "expect grade to be added to the context" do
    expect { described_class.execute user: user }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expects a user to be added to the context" do
    expect { described_class.execute grade: grade }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "adds attributes to the grade" do
    result = described_class.execute grade: grade, user: user
    expect(result[:grade].graded_at).to be_within(1.second).of(Time.now)
    expect(result[:grade].graded_by_id).to eq user.id
    expect(result[:grade].instructor_modified).to be_truthy
  end
end
