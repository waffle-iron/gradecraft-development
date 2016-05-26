require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_earned_badge/creates_earned_badge"

describe Services::Actions::CreatesEarnedBadge do
  let(:world) { World.create.with(:course, :assignment, :student, :badge, :grade) }

  let(:attributes) do
    {
      student_id: world.student.id,
      badge_id: world.badge.id,
      assignment_id: world.assignment.id,
      grade_id: world.grade.id,
      score: 800,
      student_visible: true,
      feedback: "You are so awesome!"
    }
  end

  it "expects attributes to create the earned badge" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "promises the created earned badge" do
    result = described_class.execute attributes: attributes
    expect(result).to have_key :earned_badge
    expect(result.earned_badge).to be_persisted
  end

  it "halts if the earned badge is invalid" do
    attributes[:student_id] = nil
    expect { described_class.execute attributes: attributes }.to \
      raise_error LightService::FailWithRollbackError
  end
end
