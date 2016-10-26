require "rails_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  include Toolkits::ModelAddons::SharedExamples

  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  it_behaves_like "ModelAddons::ImprovedLogging is included"

  describe "fetch_assets" do
    let(:fetch_assets) do
      subject.instance_eval { fetch_assets }
    end

    it "gets the submissions export assignment" do
      fetch_assets
      expect(performer.assignment).to eq submissions_export.assignment
    end

    it "gets the submissions export course" do
      fetch_assets
      expect(performer.course).to eq submissions_export.course
    end

    it "gets the submissions export professor" do
      fetch_assets
      expect(performer.professor).to eq submissions_export.professor
    end

    it "gets the submissions export team" do
      fetch_assets
      expect(performer.team).to eq submissions_export.team
    end

    it "fetches the students" do
      expect(performer).to receive(:fetch_students)
      fetch_assets
    end

    it "fetches the submitters for the csv" do
      expect(performer).to receive(:fetch_submitters_for_csv)
      fetch_assets
    end

    it "fetches submissions" do
      expect(performer).to receive(:fetch_submissions)
      fetch_assets
    end
  end

  describe "fetch_students" do
    context "a team is present" do
      let(:students_ivar) { performer_with_team.instance_variable_get(:@students) }
      subject { performer_with_team.instance_eval { fetch_students }}

      before(:each) do
        allow(performer_with_team.submissions_export).to receive(:has_team?) { true }
        performer_with_team.instance_variable_set(:@assignment, assignment)
        performer_with_team.instance_variable_set(:@team, team)
        allow(assignment).to receive(:students_with_text_or_binary_files_on_team) { students }
      end

      it "returns the submissions being graded for that team" do
        expect(assignment).to receive(:students_with_text_or_binary_files_on_team).with(team)
        subject
      end

      it "fetches the students" do
        subject
        expect(students_ivar).to eq(students)
      end
    end

    context "no team is present" do
      let(:students_ivar) { performer.instance_variable_get(:@students) }
      subject { performer.instance_eval { fetch_students }}

      before(:each) do
        allow(performer.submissions_export).to receive(:has_team?) { false }
        performer.instance_variable_set(:@team, nil)
        allow(assignment).to receive(:students_with_text_or_binary_files) { students }
        performer.instance_variable_set(:@assignment, assignment)
      end

      it "returns the submissions being graded for that team" do
        expect(assignment).to receive(:students_with_text_or_binary_files)
        subject
      end

      it "fetches the students" do
        subject
        expect(students_ivar).to eq(students)
      end
    end
  end

  describe "fetch_submitters_for_csv" do
    let(:fetch_submitters_for_csv) do
      performer.instance_eval { fetch_submitters_for_csv }
    end

    context "the submissions export uses groups" do
      it "returns groups for the course" do
        group = double(:group)
        allow(performer.submissions_export).to receive(:use_groups) { true }
        allow(Group).to receive(:where).with(course: course) { [group] }

        expect(fetch_submitters_for_csv).to eq [group]
      end
    end

    context "the submissions export has a team" do
      it "returns the students on the given team" do
      end
    end

    context "submissions export has no team" do
      it "returns all students in the course" do
      end
    end
  end

  describe "fetch_submissions" do
    context "the SubmissionsExport has a team" do
      it "returns the student submissions with files for the team" do
        team = create :team
        performer.instance_variable_set :@team, team

        allow(performer.assignment)
          .to receive(:students_with_text_or_binary_files_on_team).with(team)
          .and_return ["some-students"]


        expect(performer.instance_eval { fetch_submissions }).to eq ["some-students"]
      end
    end

    context "the SubmissionsExport has no team" do
      it "returns all student submissions with files for the course" do
      end
    end
  end
end
