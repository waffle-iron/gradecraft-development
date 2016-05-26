require "rails_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  describe "mailer outcomes" do
    describe "#deliver_outcome_mailer" do
      subject { performer.instance_eval { deliver_outcome_mailer } }

      before(:each) do
        performer.instance_variable_set(:@check_s3_upload_success, nil)
      end

      context "the s3 upload is successful" do
        before { allow(performer).to receive(:check_s3_upload_success) { true }}

        it "should deliver the success mailer" do
          expect(performer).to receive(:deliver_archive_success_mailer)
          subject
        end
      end

      context "the s3 upload failed" do
        before do
          allow(performer).to receive(:check_s3_upload_success) { false }
        end

        it "should deliver the failure mailer" do
          expect(performer).to receive(:deliver_archive_failed_mailer)
          subject
        end
      end
    end

    describe "#deliver_archive_success_mailer" do
      subject { performer.instance_eval { deliver_archive_success_mailer } }

      context "a @team is present" do
        before { performer.instance_variable_set(:@team, true) }

        it "should deliver the team success mailer" do
          expect(performer).to receive(:deliver_team_export_successful_mailer)
          subject
        end
      end

      context "no @team is present" do
        before { performer.instance_variable_set(:@team, false) }

        it "should deliver the non-team success mailer" do
          expect(performer).to receive(:deliver_export_successful_mailer)
          subject
        end
      end
    end

    describe "#deliver_archive_failed_mailer" do
      subject { performer.instance_eval { deliver_archive_failed_mailer } }

      context "a @team is present" do
        before { performer.instance_variable_set(:@team, true) }

        it "should deliver the team failure mailer" do
          expect(performer).to receive(:deliver_team_export_failure_mailer)
          subject
        end
      end

      context "no @team is present" do
        before { performer.instance_variable_set(:@team, false) }

        it "should deliver the non-team failure mailer" do
          expect(performer).to receive(:deliver_export_failure_mailer)
          subject
        end
      end
    end
  end

  describe "mailer methods" do
    let(:professor) { create(:user) }
    let(:assignment) { create(:assignment) }
    let(:team) { create(:team) }
    let(:submissions_export) { create(:submissions_export) }
    let(:secure_token) { create(:secure_token) }
    let(:mailer_double) { double("mailer something").as_null_object }

    before(:each) do
      [:professor, :assignment, :team, :submissions_export].each do |attr|
        performer.instance_variable_set "@#{attr}", send(attr)
      end

      allow(performer).to receive(:secure_token) { secure_token }
      allow(mailer_double).to receive(:deliver_now)
    end

    after(:each) do
      subject
    end

    describe "#deliver_export_successful_mailer" do
      subject { performer.instance_eval { deliver_export_successful_mailer } }

      before(:each) do
        allow(ExportsMailer).to receive(:submissions_export_success)
          .and_return mailer_double
      end

      it "creates an export success mailer" do
        expect(ExportsMailer).to receive(:submissions_export_success)
          .with(professor, assignment, submissions_export, secure_token)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_team_export_successful_mailer" do
      subject do
        performer.instance_eval { deliver_team_export_successful_mailer }
      end

      before(:each) do
        allow(ExportsMailer).to receive(:team_submissions_export_success)
          .and_return mailer_double
      end

      it "delivers a team export success mailer" do
        expect(ExportsMailer).to receive(:team_submissions_export_success)
          .with(professor, assignment, team, submissions_export, secure_token)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_export_failure_mailer" do
      subject { performer.instance_eval { deliver_export_failure_mailer } }

      before(:each) do
        allow(ExportsMailer).to receive(:submissions_export_failure)
          .and_return mailer_double
      end

      it "delivers an export failure mailer" do
        expect(ExportsMailer).to receive(:submissions_export_failure)
          .with(professor, assignment)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end

    describe "#deliver_team_export_failure_mailer" do
      subject { performer.instance_eval { deliver_team_export_failure_mailer } }

      before(:each) do
        allow(ExportsMailer).to receive(:team_submissions_export_failure)
          .and_return mailer_double
      end

      it "delivers a team export failure mailer" do
        expect(ExportsMailer).to receive(:team_submissions_export_failure)
          .with(professor, assignment, team)
      end

      it "delivers the mailer" do
        expect(mailer_double).to receive(:deliver_now)
      end
    end
  end
end
