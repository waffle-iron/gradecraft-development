require "active_record_spec_helper"
require "spec_helpers/resque_job_spec_helper"

require_relative "../../app/performers/gradebook_export_performer"
require_relative "../../app/performers/multiplied_gradebook_export_performer"
require_relative "../../app/background_jobs/multiplied_gradebook_exporter_job"


RSpec.describe MultipliedGradebookExporterJob do
  include InQueueHelper # pulled from ResqueSpec

  it "queues the job in the proper queue" do
    expect(described_class.queue).to eq :multiplied_gradebook_exporter
  end

  it "runs the correct performer" do
    expect(described_class.performer_class).to eq MultipliedGradebookExportPerformer
  end
end
