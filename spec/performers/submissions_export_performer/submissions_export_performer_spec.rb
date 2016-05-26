require "rails_spec_helper"
require "active_record_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  include Toolkits::ModelAddons::SharedExamples

  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  it_behaves_like "ModelAddons::ImprovedLogging is included"

  # private and protected methods

  describe "sorted_student_directory_keys" do
    let(:contrived_student_submissions_hash) {{ "dave_hoggworthy"=>"", "carla_makeshift"=>"", "bordwell_hamhock"=>"" }}
    let(:expected_keys_result) { %w[ bordwell_hamhock carla_makeshift dave_hoggworthy ] }

    before do
      allow(performer).to receive(:submissions_grouped_by_student) { contrived_student_submissions_hash }
    end

    it "sorts the keys alphabetically" do
      expect(performer.instance_eval { sorted_student_directory_keys }).to eq(expected_keys_result)
    end
  end

  describe "generate_export_csv" do
    subject { performer.instance_eval { generate_export_csv }}
    let(:students_for_csv) { create_list(:user, 2) }
    let(:csv_path) { performer.instance_eval { csv_file_path }}

    before(:each) do
      performer.instance_variable_set(:@students_for_csv, students_for_csv)
      performer.instance_variable_set(:@assignment, assignment)
      allow(assignment).to receive(:grade_import) { CSV.generate {|csv| csv << ["dogs", "are", "nice"]} }
    end

    it "saves the result of assignment#grade_import" do
      subject
      expect(CSV.read(csv_path).first).to eq(["dogs", "are", "nice"])
    end

    it "sends an array of students to assignment#grade_import" do
      expect(assignment).to receive(:grade_import).with(students_for_csv)
      subject
    end
  end

  # @submissions_export[:team_id].present?
  describe "team_present?" do
    before(:each) { performer.instance_variable_set(:@submissions_export, submissions_export) }

    context "the @submissions_export has a team_id" do
      let(:submissions_export) { create(:submissions_export, team_id: nil) }
      subject { performer.instance_eval { team_present? }}
      it { should be_falsey }
    end

    context "the @submissions_export doesn't have a team_id" do
      let(:submissions_export) { create(:submissions_export, team_id: team.id) }
      subject { performer_with_team.instance_eval { team_present? }}
      it { should be_truthy }
    end
  end

  describe "confirm_export_csv_integrity" do
    subject { performer.instance_eval { confirm_export_csv_integrity }}
    let(:tmp_dir) { Dir.mktmpdir }
    let(:test_file_path) { File.expand_path("csv_test.txt", tmp_dir) }

    context "the csv was successfully created" do
      before do
        File.open(test_file_path, "w") {|f| f.write("test file") }
        allow(performer).to receive(:csv_file_path) { test_file_path }
      end

      it "returns true" do
        expect(subject).to be_truthy
      end

      it "sets an @confirm_export_csv_integrity ivar" do
        subject
        expect(performer.instance_variable_get(:@confirm_export_csv_integrity)).to be_truthy
      end

      it "caches the value" do
        subject # call it once to cache it
        expect(File).to_not receive(:exist?).with("csv_test.txt")
        subject # shouldn't check again after caching
      end

      after do
        File.delete(test_file_path) if File.exist?(test_file_path)
      end
    end

    context "the csv was not created" do
      let(:false_file_path) { File.expand_path("false_test.txt", tmp_dir) }

      before do
        allow(performer).to receive(:csv_file_path) { "false_test.txt" }
      end

      it "returns false" do
        expect(subject).to be_falsey
      end

      it "doesn't cache the value" do
        expect(performer.instance_variable_get(:@confirm_export_csv_integrity)).to eq(nil)
      end

      after do
        File.delete(false_file_path) if File.exist?(false_file_path)
      end
    end

  end

  describe "csv_file_path" do
    subject { performer.instance_eval { csv_file_path }}
    it "uses the grade import template" do
      expect(subject).to match(/grade_import_template\.csv$/)
    end

    it "expands the path off of archive_root_dir" do
      allow(performer).to receive(:archive_root_dir) { "/some/weird/path/" }
      expect(subject).to match(/^\/some\/weird\/path\//)
    end

    it "caches the file path" do
      cached_call = subject
      expect(subject).to eq(cached_call)
    end
  end

  describe "work_resources_present?" do
    let(:assignment_present) { performer.instance_variable_set(:@assignment, true) }
    let(:assignment_not_present) { performer.instance_variable_set(:@assignment, false) }
    let(:students_present) { performer.instance_variable_set(:@students, true) }
    let(:students_not_present) { performer.instance_variable_set(:@students, false) }

    subject { performer.instance_eval { work_resources_present? }}

    context "both @assignment and @students are present" do
      before { assignment_present; students_present }
      it { should be_truthy }
    end

    context "@assignment is present but @students are not" do
      before { assignment_present; students_not_present }
      it { should be_falsey }
    end

    context "@students is present but @assignment is not" do
      before { students_present; assignment_not_present }
      it { should be_falsey }
    end

    context "neither @students nor @assignment are present" do
      before { students_not_present; assignment_not_present }
      it { should be_falsey }
    end
  end

  describe "submissions_by_student" do
    let(:student1) { create(:user, first_name: "Ben", last_name: "Bailey", username: "benfriend") }
    let(:student2) { create(:user, first_name: "Mike", last_name: "McCaffrey") }
    let(:student3) { create(:user, first_name: "Dana", last_name: "Dafferty") }
    let(:student4) { create(:user, first_name: "Ben", last_name: "Bailey", username: "benweirdo") }

    let(:submission1) { double(:submission, id: 1, student: student1) }
    let(:submission2) { double(:submission, id: 2, student: student2) }
    let(:submission3) { double(:submission, id: 3, student: student3) }
    let(:submission4) { double(:submission, id: 4, student: student2) } # note that this uses student 2
    let(:submission5) { double(:submission, id: 5, student: student4) }

    let(:grouped_submission_expectation) {{
      "Bailey, Ben - Benfriend" => [submission1],
      "McCaffrey, Mike" => [submission2, submission4],
      "Dafferty, Dana" => [submission3],
      "Bailey, Ben - Benweirdo" => [submission5]
    }}

    let(:submissions_by_id) { [submission1, submission2, submission3, submission4, submission5].sort_by(&:id) }

    before(:each) do
      performer.instance_variable_set(:@submissions, submissions_by_id)
      performer.instance_variable_set(:@students, [ student1, student2, student3, student4 ])
    end

    subject do
      performer.instance_eval { submissions_grouped_by_student }
    end

    it "should reorder the @submissions array by student" do
      expect(subject).to eq(grouped_submission_expectation)
    end

    it "should use 'last_name_first_name-id' for the hash keys" do
      expect(subject.keys.first).to eq("Bailey, Ben - Benfriend")
    end

    it "should return an array of submissions for each student" do
      expect(subject["McCaffrey, Mike"]).to eq([submission2, submission4])
    end
  end

  describe "s3 concerns" do
    before do
      performer.instance_variable_set(:@submissions_export, submissions_export)
      allow(performer).to receive(:expanded_archive_base_path) { "/this/weird/path" }
    end

    describe "#upload_archive_to_s3" do
      subject { performer.instance_eval { upload_archive_to_s3 }}

      it "calls #upload_file_to_s3 on the submissions export with the file path" do
        expect(submissions_export).to receive(:upload_file_to_s3).with("/this/weird/path.zip")
        subject
      end
    end

    describe "check_s3_upload_success" do
      subject { performer.instance_eval { check_s3_upload_success }}

      it "checks if the object exists on S3 through the submissions export" do
        expect(submissions_export).to receive(:s3_object_exists?)
        subject
      end
    end
  end

  describe "#secure_token" do
    let(:result) { performer.instance_eval { secure_token } }
    let!(:professor) { create(:user) }
    let!(:course) { create(:course) }

    before do
      allow(performer).to receive_messages(
        professor: professor,
        course: course,
        submissions_export: submissions_export
      )
    end

    it "creates a secure token with the professor and course ids" do
      expect(result.user_id).to eq professor.id
      expect(result.course_id).to eq course.id
      expect(result.target).to eq performer.submissions_export
      expect(result.class).to eq SecureToken
      expect(result).to be_valid
    end

    it "caches the secure token" do
      result
      expect(SecureToken).not_to receive(:create)
      result
    end

    it "sets the secure token to @secure_token" do
      result
      expect(performer.instance_variable_get(:@secure_token)).to eq result
    end
  end
end
