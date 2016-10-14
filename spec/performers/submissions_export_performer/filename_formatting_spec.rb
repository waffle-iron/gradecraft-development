require "rails_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  describe "student_directory_file_path" do
    let(:student_double) { double(:student) }
    let(:result) do
      performer.instance_eval do
        student_directory_file_path(@some_student, "whats_up.doc")
      end
    end

    before do
      performer.instance_variable_set(:@some_student, student_double)
      allow(performer).to receive(:student_directory_path) { "/this/great/path" }
    end

    it "gets the student directory path from the student" do
      expect(performer).to receive(:student_directory_path).with(student_double)
      result
    end

    it "builds the correct path relative to the student directory" do
      expect(result).to eq("/this/great/path/whats_up.doc")
    end
  end

  describe "#archive_root_dir" do
    let(:archive_root_dir_path) { Dir.mktmpdir }
    subject { performer.instance_eval { archive_root_dir }}
    before(:each) do
      performer.instance_variable_set(:@archive_root_dir, nil)
      allow(performer).to receive(:archive_root_dir_path) { archive_root_dir_path }
    end

    it "returns the archive root dir path" do
      expect(subject).to eq(archive_root_dir_path)
    end

    it "recursively builds the archive root dir path" do
      allow(FileUtils).to receive(:mkdir_p) {[archive_root_dir_path]}
      expect(FileUtils).to receive(:mkdir_p).with(archive_root_dir_path)
      subject
    end

    it "actually builds the archive root dir" do
      subject
      expect(Dir.exist?(archive_root_dir_path)).to be_truthy
    end

    it "caches the root dir path" do
      subject
      expect(FileUtils).not_to receive(:mkdir_p).with(archive_root_dir_path)
      subject
      expect(performer.instance_variable_get :@archive_root_dir)
        .to eq(archive_root_dir_path)
    end
  end

  describe "tmp_dir" do
    subject { performer.instance_eval { tmp_dir }}
    it "builds a temporary directory" do
      expect(subject).to match(/\/(tmp|var\/folders)\/[\w\d-]+/) # match the tmp dir hash
    end

    it "caches the temporary directory" do
      original_tmp_dir = subject
      expect(subject).to eq(original_tmp_dir)
      expect(performer.instance_variable_get(:@tmp_dir)).to eq(subject)
    end
  end

  describe "archive_tmp_dir" do
    subject { performer.instance_eval { archive_tmp_dir }}

    it "builds a temporary directory for the archive" do
      expect(S3fs).to receive(:mktmpdir)
      subject
    end

    it "caches the temporary directory" do
      original_tmp_dir = subject
      expect(subject).to eq(original_tmp_dir)
      expect(performer.instance_variable_get(:@archive_tmp_dir)).to eq(subject)
    end
  end

  describe "expanded_archive_base_path" do
    subject { performer.instance_eval { expanded_archive_base_path }}
    before do
      allow(performer.submissions_export).to receive(:export_file_basename) { "the_best_filename" }
      allow(performer).to receive(:archive_tmp_dir) { "/archive/tmp/dir" }
    end

    it "expands the export file basename from the archive tmp dir path" do
      expect(subject).to eq("/archive/tmp/dir/the_best_filename")
    end

    it "caches the basename" do
      subject
      expect(performer).not_to receive(:export_file_basename)
      expect(performer.instance_variable_get(:@expanded_archive_base_path)).to eq(subject)
    end
  end
end
