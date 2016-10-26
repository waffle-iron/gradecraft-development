require "rails_spec_helper"

RSpec.describe "SubmissionsExport attributes", type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  describe "#submissions_export_attributes" do
    subject { performer.submissions_export_attributes }
    before(:each) do
      performer.instance_variable_set(:@submissions_export, submissions_export)
      allow(Time).to receive(:now) { Date.parse("Oct 20 1984").to_time }
    end

    context "the submissions export has been performed at least once" do
      let(:submissions_export) do
        create :submissions_export, last_export_started_at: Time.now
      end

      it "returns the base export attributes combined with the progress reset attributes" do
        expect(subject).to eq performer.base_export_attributes
          .merge last_completed_step: nil
      end
    end

    context "the submissions export has not been performed yet" do
      let(:submissions_export) do
        create :submissions_export, last_export_started_at: nil
      end

      it "just returns the base export attributes" do
        expect(subject).to eq performer.base_export_attributes
      end
    end
  end

  describe "#base_export_attributes" do
    before do
      allow(performer).to receive_messages({
        submissions_snapshot: {some: "hash"}
      })
    end

    subject { performer.base_export_attributes }
    let(:export_start_time) { Date.parse("Jan 20 1987").to_time }

    it "should include the student ids" do
      expect(subject[:submitter_ids]).to eq(performer.instance_variable_get(:@submitters).collect(&:id))
    end

    it "should include the last export started time" do
      allow(Time).to receive(:now) { export_start_time }
      expect(subject[:last_export_started_at]).to eq(export_start_time)
    end

    it "should include the submissions snapshot" do
      expect(subject[:submissions_snapshot]).to eq({some: "hash"})
    end
  end
end
