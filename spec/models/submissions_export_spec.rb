require "active_record_spec_helper"
require_relative "../support/uni_mock/rails"

RSpec.describe SubmissionsExport do
  subject { SubmissionsExport.new }

  include UniMock::StubRails

  let(:s3_manager) { double(S3Manager::Manager) }
  let(:s3_object_key) { double(:s3_object_key) }

  let(:course) { create(:course) }
  let(:professor) { create(:user) }
  let(:team) { create(:team) }
  let(:assignment) { create(:assignment) }

  let(:submissions_export_associations) {{
    course: course,
    professor: professor,
    team: team,
    assignment: assignment
  }}

  describe "associations" do
    subject { create(:submissions_export, submissions_export_associations) }

    it "belongs to a course" do
      expect(subject.course).to eq(course)
    end

    it "belongs to a professor" do
      expect(subject.professor).to eq(professor)
    end

    it "belongs to a team" do
      expect(subject.team).to eq(team)
    end

    it "belongs to an assignment" do
      expect(subject.assignment).to eq(assignment)
    end
  end

  describe "callbacks" do
    subject { create(:submissions_export) }

    describe "rebuilding the s3 object key before save" do
      context "export_filename changed" do
        it "rebuilds the s3 object key" do
          expect(subject).to receive(:rebuild_s3_object_key)
          subject.update_attributes export_filename: "some_filename.txt"
        end
      end

      context "export_filename did not change" do
        it "doesn't rebuild the s3 object key" do
          expect(subject).not_to receive(:rebuild_s3_object_key)
          subject.update_attributes team_id: 5
        end
      end
    end
  end

  describe "#downloadable?" do
    let(:result) { subject.downloadable? }

    context "export has a last_export_completed_at time" do
      it "is downloadable" do
        subject.last_export_completed_at = Time.now
        expect(result).to be_truthy
      end
    end

    context "export doesn't have a last_export_completed_at time" do
      it "isn't download able" do
        subject.last_export_completed_at = nil
        expect(result).to be_falsey
      end
    end
  end

  describe "#update_export_completed_time" do
    let(:time_now) { Date.parse("Oct 20 1999").to_time }

    it "updates the last_export_completed_at time to now" do
      allow(Time).to receive(:now) { time_now }
      subject.update_export_completed_time
      expect(subject.last_export_completed_at).to eq(time_now)
    end
  end

  describe "#created_at_date" do
    subject { create(:submissions_export) }
    let(:result) { subject.created_at_date }

    context "created_at is present" do
      it "formats the created_at date" do
        expect(result).to eq subject.created_at.strftime("%F")
      end
    end

    context "created_at is nil" do
      it "returns nil" do
        allow(subject).to receive(:created_at) { nil }
        expect(result).to be_nil
      end
    end
  end

  describe "#created_at_in_microseconds" do
    subject { create(:submissions_export) }
    let(:result) { subject.created_at_in_microseconds }

    context "created_at is present" do
      it "formats the created_at time in microseconds" do
        expect(result).to eq subject.created_at.to_f.to_s.delete(".")
      end
    end

    context "created_at is nil" do
      it "returns nil" do
        allow(subject).to receive(:created_at) { nil }
        expect(result).to be_nil
      end
    end
  end

  describe "validations" do
    describe "course_id" do
      let(:result) { create(:submissions_export, course: nil) }
      it "requires a course_id" do
        expect { result }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    describe "assignment_id" do
      let(:result) { create(:submissions_export, course: nil) }

      it "requires an assignment_id" do
        expect { result }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe "#rebuild_s3_object_key" do
    before do
      allow(subject).to receive_messages(
        build_s3_object_key: "new-key",
        export_filename: "some_filename.txt"
      )
    end

    it "builds a new s3_object_key and caches it" do
      subject.rebuild_s3_object_key
      expect(subject[:s3_object_key]).to eq "new-key"
    end
  end

  describe "#build_s3_object_key" do
    subject { create(:submissions_export) }
    let(:result) { subject.build_s3_object_key("stuff.zip") }

    let(:expected_base_s3_key) do
      "exports/courses/40/assignments/50" \
      "/#{subject.created_at_date}" \
      "/#{subject.created_at_in_microseconds}/stuff.zip"
    end

    before(:each) do
      allow(subject).to receive_messages(course_id: 40, assignment_id: 50)
      ENV["AWS_S3_DEVELOPER_TAG"] = "jeff-moses"
    end

    context "env is development" do
      before { stub_env "development" }

      it "prepends the developer tag to the store dirs and joins them" do
        expect(result).to eq ["jeff-moses", expected_base_s3_key].join("/")
      end
    end

    context "env is anything but development" do
      before { stub_env "sumpin-else" }

      it "joins the store dirs and doesn't use the developer tag" do
        expect(result).to eq expected_base_s3_key
      end
    end
  end

  describe "#s3_object_key_prefix" do
    subject { create(:submissions_export) }
    let(:result) { subject.s3_object_key_prefix }
    let(:expected_object_key_prefix) do
      [
        "exports", "courses", 40, "assignments", 50,
        subject.created_at_date,
        subject.created_at_in_microseconds
      ]
    end

    it "returns the expected pieces" do
      allow(subject).to \
        receive_messages(course_id: 40, assignment_id: 50)
      expect(result).to eq expected_object_key_prefix.join("/")
    end
  end

  describe "#update_export_completed_time" do
    let(:result) { subject.update_export_completed_time }
    let(:sometime) { Date.parse("Oct 20 1982").to_time }

    before { allow(Time).to receive(:now) { sometime } }

    it "calls update_attributes on the submissions export with the export time" do
      expect(subject).to receive(:update_attributes)
        .with(last_export_completed_at: sometime)
      result
    end

    it "updates the last_export_completed_at timestamp to now" do
      result
      expect(subject.last_export_completed_at).to eq(sometime)
    end
  end
end
