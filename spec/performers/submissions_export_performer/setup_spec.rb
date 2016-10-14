require "rails_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  describe "#setup" do
    subject { performer.setup }

    it "ensures that the s3fs tmpdir exists" do
      expect(S3fs).to receive(:ensure_tmpdir)
      performer
    end

    it "finds the submissions export by id" do
      allow(SubmissionsExport).to receive(:find) { create(:submissions_export) }
      expect(SubmissionsExport).to receive(:find).with(submissions_export.id)
      subject
    end

    it "fetches the assets" do
      expect(performer).to receive(:fetch_assets)
      subject
    end

    it "creates an submissions export record from the attributes" do
      allow(SubmissionsExport).to receive(:find) { submissions_export }
      expect(submissions_export).to receive(:update_attributes).at_least(:once)
      subject
    end

    it "sets an instance variable for the created submissions export" do
      subject
      expect(performer.instance_variable_get(:@submissions_export)).to eq(submissions_export)
    end

    it "creates an empty array for error handling" do
      subject
      expect(performer.instance_variable_get(:@errors)).to eq([])
    end
  end
end
