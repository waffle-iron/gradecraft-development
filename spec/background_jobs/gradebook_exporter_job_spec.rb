require "active_record_spec_helper"
require "spec_helpers/resque_job_spec_helper"

require_relative "../../app/performers/gradebook_export_performer"
require_relative "../../app/background_jobs/gradebook_exporter_job"

RSpec.describe GradebookExporterJob do
  include InQueueHelper # pulled from ResqueSpec
  let(:user) { create(:user) }
  let(:course) { create(:course) }
  let(:job_attributes) { {user_id: user.id, course_id: course.id} }

  describe "#enqueue" do
    before(:each) { ResqueSpec.reset! }
    let(:gradebook_exporter_queue) { queue(GradebookExporterJob) }
    subject { GradebookExporterJob.new(job_attributes).enqueue }

    it "increases the queue size by one" do
      expect{ subject }.to change { queue(GradebookExporterJob).size }.by(1)
    end

    it "queues the job with the correct arguments" do
      subject
      expect(gradebook_exporter_queue.last[:args]).to eq([job_attributes])
    end

    it "queues the job in the proper queue" do
      subject
      expect(gradebook_exporter_queue.last[:class]).to eq(GradebookExporterJob.to_s)
    end
  end

  describe "#enqueue_in" do
    subject { GradebookExporterJob.new(job_attributes).enqueue_in(10) }

    it "schedules the job in little while" do
      subject
      expect(GradebookExporterJob).to have_scheduled(job_attributes).in(10)
    end

    it "doesn't add the job to the queue yet" do
      expect{ subject }.to change { queue(GradebookExporterJob).size }.by(0)
    end

    it "uses the correct arguments" do
      subject
      expect(GradebookExporterJob).to have_scheduled(job_attributes).in(10)
    end
  end

  describe "#enqueue_at" do
    let(:later) { Time.now + 50 }
    subject { GradebookExporterJob.new(job_attributes).enqueue_at(later) }

    it "schedules the job for later" do
      subject
      expect(GradebookExporterJob).to have_scheduled(job_attributes).at(later)
    end

    it "doesn't add the job to the queue yet" do
      expect{ subject }.to change { queue(GradebookExporterJob).size }.by(0)
    end

    it "uses the correct arguments" do
      subject
      expect(GradebookExporterJob).to have_scheduled(job_attributes).at(later)
    end
  end
end
