require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_criterion_grade/builds_criterion_grades"

describe Services::Actions::BuildsCriterionGrades do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion, :criterion_grade, :badge, :group) }
  let(:raw_params) { RubricGradePUT.new(world).params }
  let(:context) do
    { raw_params: raw_params, student: world.student, assignment: world.assignment }
  end

  it "expects attributes to assign to criterion grades" do
    context.delete(:raw_params)
    expect { described_class.execute context }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expect student to be added to the context" do
    context.delete(:student)
    expect { described_class.execute context }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "expect assignment to be added to the context" do
    context.delete(:assignment)
    expect { described_class.execute context }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "promises the built criterion grades" do
    result = described_class.execute context
    expect(result).to have_key :criterion_grades
  end

  it "builds a criterion_grade for each record in the params" do
    result = described_class.execute context
    expect(result[:criterion_grades].length).to \
      eq(raw_params["criterion_grades"].length)
  end
end
