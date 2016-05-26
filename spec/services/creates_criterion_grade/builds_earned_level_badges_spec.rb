require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_criterion_grade/builds_earned_level_badges"

describe Services::Actions::BuildsEarnedLevelBadges do
  let(:world) { World.create.with(:course, :student, :assignment, :rubric, :criterion, :criterion_grade, :badge) }
  let(:raw_params) { RubricGradePUT.new(world).params }
  let(:context) do
    { raw_params: raw_params,
      student_visible_status: true,
      student: world.student,
      assignment: world.assignment
    }
  end
  let(:badge_id) { context[:raw_params]["level_badges"][0]["badge_id"] }
  let(:level_id) { context[:raw_params]["level_badges"][0]["level_id"] }

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

  it "expect student visible status to be added to the context" do
    context.delete(:student_visible_status)
    expect { described_class.execute context }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "promises the built earned level badges" do
    result = described_class.execute context
    expect(result).to have_key :earned_level_badges
    expect(result[:earned_level_badges].first.student_visible).to be_truthy
  end

  it "builds an earned badge for each record in the params" do
    result = described_class.execute context
    expect(result[:earned_level_badges].length).to \
      eq(raw_params["level_badges"].length)
  end

  it "transfers the student visible state to the EarnedBadge" do
    result = described_class.execute context
  end

  # See note above #destroy_exisiting_earned_badges
  # This should not be the expected behavior
  it "clears out old badges" do
    EarnedBadge.create(badge_id: badge_id, student_id: world.student.id, assignment_id: world.assignment.id)
    expect { described_class.execute context }.to change { EarnedBadge.count }.by(-1)
  end
end
