require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_earned_badge/recalculates_student_score"

describe Services::Actions::RecalculatesStudentScore do
  let(:earned_badge) { create :earned_badge }

  before do
    class FakeJob
      def initialize(attributes); end
      def enqueue; end
    end

    stub_const("ScoreRecalculatorJob", FakeJob)
  end

  it "expects an earned badge to recalculate the score for" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "recalculates the score if there is a point total" do
    expect_any_instance_of(ScoreRecalculatorJob).to receive(:enqueue)
    described_class.execute earned_badge: earned_badge
  end

  it "does not recalculate the score if there is no point total" do
    earned_badge.badge.update_attributes(point_total: nil)
    expect_any_instance_of(ScoreRecalculatorJob).to_not receive(:enqueue)
    described_class.execute earned_badge: earned_badge
  end
end
