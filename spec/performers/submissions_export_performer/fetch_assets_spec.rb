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
    subject { performer.instance_eval { fetch_assets }}
    before { performer.instance_variable_set(:@submissions_export, submissions_export) }

    describe "assignment submissions export" do
      it_behaves_like "an submissions export resource", :professor, User # this is a User object fetched as "professor"
      it_behaves_like "an submissions export resource", :assignment
      it_behaves_like "an submissions export resource", :course
    end

    describe "team submissions export" do
      let(:performer) { performer_with_team }
      it_behaves_like "an submissions export resource", :team
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
    context "a team is present" do
      let(:submissions_ivar) { performer_with_team.instance_variable_get(:@submissions) }
      subject { performer_with_team.instance_eval { fetch_submissions }}

      before(:each) do
        allow(performer_with_team.submissions_export).to receive(:has_team?) { true }
        performer_with_team.instance_variable_set(:@assignment, assignment)
        performer_with_team.instance_variable_set(:@team, team)
        allow(assignment).to receive(:student_submissions_with_files_for_team) { submissions }
      end

      it "returns the submissions being graded for that team" do
        expect(assignment).to receive(:student_submissions_with_files_for_team).with(team)
        subject
      end

      it "fetches the submissions" do
        subject
        expect(submissions_ivar).to eq(submissions)
      end
    end

    context "no team is present" do
      let(:submissions_ivar) { performer.instance_variable_get(:@submissions) }
      subject { performer.instance_eval { fetch_submissions }}

      before(:each) do
        allow(performer.submissions_export).to receive(:has_team?) { false }
        performer.instance_variable_set(:@assignment, assignment)
        performer.instance_variable_set(:@team, team)
        allow(assignment).to receive(:student_submissions_with_files) { submissions }
      end

      it "returns submissions being graded for the assignment" do
        expect(assignment).to receive(:student_submissions_with_files)
        subject
      end

      it "fetches the submissions" do
        subject
        expect(submissions_ivar).to eq(submissions)
      end
    end
  end
end
