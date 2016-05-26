require "rails_spec_helper"

RSpec.describe SubmissionsExportsController, type: :controller do

  let(:teams) { create_list(:team, 2) }
  let(:team) { teams.first }
  let(:course) { create(:course, teams: teams) }
  let(:submissions_exports) { create_list(:submissions_export, 2, course: course, assignment: assignment, s3_object_key: "some thing") }
  let(:submissions_export) { create(:submissions_export, course: course, assignment: assignment, s3_object_key: "some thing") }
  let(:assignment) { create(:assignment) }
  let(:professor) { create(:professor_course_membership, course: course).user }

  before do
    login_user(professor)
    allow(controller).to receive(:current_course) { course }
    allow(controller).to receive(:current_user) { professor }
  end

  describe "POST #create" do
    subject { post :create, assignment_id: assignment.id, team_id: team.id }

    it "creates an submissions export" do
      expect(controller).to receive(:create_submissions_export)
      subject
    end

    describe "enqueuing the submissions export job" do
      context "the submissions export job is enqueued" do
        before { allow(controller).to receive_message_chain(:submissions_export_job, :enqueue) { true } }
        it "sets the job success flash message" do
          subject
          expect(flash[:success]).to match(/Your submissions export is being prepared/)
        end
      end

      context "submissions export job is not enqueued" do
        before { allow(controller).to receive_message_chain(:submissions_export_job, :enqueue) { false } }
        it "sets the job failure flash message" do
          subject
          expect(flash[:alert]).to match(/Your submissions export failed to build/)
        end
      end
    end

    it "redirects to the assignment page for the given assignment" do
      subject
      expect(response).to redirect_to(assignment_path(assignment))
    end
  end

  describe "DELETE #destroy" do
    subject { delete :destroy, id: submissions_export.id }

    before(:each) do
      allow(controller).to receive(:submissions_export) { submissions_export }
    end

    describe "determining success and failure" do
      context "the submissions export is destroyed and the s3 object deleted" do
        before do
          allow(submissions_export).to receive(:delete_object_from_s3) { true }
        end

        it "destroys the submissions export" do
          expect(submissions_export).to receive(:destroy)
          subject
        end

        it "notifies the user of success" do
          subject
          expect(flash[:success]).to match(/Assignment export successfully deleted/)
        end
      end

      context "the submissions export is not destroyed and the s3 object fails to delete" do
        before do
          allow(submissions_export).to receive(:delete_object_from_s3) { false }
        end

        it "notifies the user of the failure" do
          subject
          expect(flash[:alert]).to match(/Unable to delete the submissions export/)
        end
      end
    end

    it "redirects to the exports path" do
      subject
      expect(response).to redirect_to(exports_path)
    end
  end

  describe "GET #download" do
    let(:result) { get :download, id: submissions_export.id }

    it "streams the s3 object to the client" do
      expect(controller).to receive(:stream_file_from_s3)
      result
    end
  end

  describe "secure downloads" do
    let(:secure_download_params) do
      {
        secure_token_uuid: secure_token.uuid,
        secret_key: secure_token.random_secret_key,
        id: submissions_export.id
      }
    end

    let(:authenticator) { SecureTokenAuthenticator.new authenticator_params }
    let(:authenticator_params) do
      secure_download_params.except(:id).merge(
        target_class: secure_token.target_type,
        target_id: secure_token.target_id
      )
    end

    let(:secure_token) { create(:secure_token, target: submissions_export) }

    describe "GET #secure_download" do
      let(:result) { get :secure_download, secure_download_params }

      before(:each) do
        allow(controller).to receive(:secure_download_authenticator)
          .and_return authenticator
      end

      context "the SecureDownloadAuthenticator authenticates" do
        before do
          allow(authenticator).to receive(:authenticates?) { true }
        end

        it "streams the s3 object to the client" do
          expect(controller).to receive(:stream_file_from_s3)
          result
        end
      end

      context "the SecureDownloadAuthenticator doesn't authenticate" do
        before do
          allow(authenticator).to receive(:authenticates?) { false }
        end

        context "the request was for a valid token that has expired" do
          it "alerts the user that their token has expired" do
            allow(authenticator).to receive(:valid_token_expired?) { true }
            result
            expect(flash[:alert]).to match /email link.*expired/
          end
        end

        context "the request completely failed to authenticate" do
          it "alerts the user that their request was invalid" do
            allow(authenticator).to receive(:valid_token_expired?) { false }
            result
            expect(flash[:alert]).to match /does not exist/
          end
        end

        it "redirects the user to the root page and tells them to log in" do
          result
          expect(flash[:alert]).to match /Please login/
          expect(response).to redirect_to root_path
        end
      end

      describe "skipped filters" do
        let(:result) { get :secure_download, secure_download_params }

        before do
          # since we just want to test filter skipping let's disregard the
          # secure token authenticator here
          allow(controller).to receive(:secure_download_authenticator)
            .and_return double(SecureTokenAuthenticator).as_null_object

          # let's disregard s3 file streaming as well
          allow(controller).to receive(:stream_file_from_s3) { false }
        end

        # make the GET secure_download call after each expectation
        after(:each) { result }

        it "doesn't require login" do
          expect(controller).not_to receive(:require_login)
        end

        it "doesn't increment the page views" do
          expect(controller).not_to receive(:increment_page_views)
        end

        it "doesn't get course scores" do
          expect(controller).not_to receive(:get_course_scores)
        end
      end
    end

    describe "#secure_download_authenticator" do
      let(:result) do
        controller.instance_eval { secure_download_authenticator }
      end

      let(:authenticator_attrs) do
        {
          secure_token_uuid: secure_token.uuid,
          secret_key: secure_token.random_secret_key,
          target_id: submissions_export.id,
          target_class: "SubmissionsExport"
        }
      end

      before do
        allow(controller).to receive(:params) { secure_download_params }
      end

      it "builds a new SecureTokenAuthenticator" do
        expect(SecureTokenAuthenticator).to receive(:new)
          .with authenticator_attrs
        result
      end

      it "caches the SecureTokenAuthenticator" do
        result
        expect(SecureTokenAuthenticator).not_to receive(:new)
        result
      end

      it "sets the returned value to @secure_token_authenticator" do
        authenticator = SecureTokenAuthenticator.new authenticator_attrs
        allow(SecureTokenAuthenticator).to receive(:new) { authenticator }
        result
        expect(controller.instance_variable_get(:@secure_download_authenticator))
          .to eq(authenticator)
      end
    end
  end

  describe "#stream_file_from_s3" do
    let(:result) do
      controller.instance_eval { stream_file_from_s3 }
    end
    let(:temp_file) { Tempfile.new("s3_object") }

    before do
      allow(controller).to receive(:submissions_export) { submissions_export }
      allow(submissions_export).to receive_messages(
        export_filename: "some_filename.txt",
        stream_s3_object_body: temp_file
      )
    end

    it "renders the s3 object data with the submissions export filename" do
      expect(controller).to receive(:send_data).with(temp_file,
        filename: "some_filename.txt")
      result
    end
  end

  describe "#submissions_export" do
    subject { controller.instance_eval { submissions_export } }
    before { allow(controller).to receive(:params) {{ id: submissions_export.id }} }

    it "fetches an submissions export by id" do
      expect(SubmissionsExport).to receive(:find).with(submissions_export.id)
      subject
    end

    it "caches the submissions export outcome" do
      subject
      expect(SubmissionsExport).not_to receive(:find).with(submissions_export.id)
      subject
    end
  end

  describe "#create_submissions_export" do
    subject { controller.instance_eval { create_submissions_export } }
    let(:submissions_export_attrs) {{
      assignment_id: assignment.id,
      course_id: course.id,
      professor_id: professor.id,
      team_id: team.id
    }}

    before do
      allow(controller).to receive(:params) {{ assignment_id: assignment.id, team_id: team.id }}
      allow(controller).to receive_messages(current_course: course, current_user: professor)
    end

    it "creates an submissions export" do
      expect(SubmissionsExport).to receive(:create).with(submissions_export_attrs)
      subject
    end

    it "caches the created submissions export" do
      subject
      expect(SubmissionsExport).not_to receive(:create)
      subject
    end
  end

  describe "#submissions_export_job" do
    subject { controller.instance_eval { submissions_export_job } }
    let(:submissions_export_job_attrs) {{ submissions_export_id: submissions_export.id }}

    before do
      controller.instance_variable_set(:@submissions_export, submissions_export)
    end

    it "instantiates a new submissions export job" do
      expect(SubmissionsExportJob).to receive(:new).with(submissions_export_job_attrs)
      subject
    end

    it "caches the submissions export job" do
      subject
      expect(SubmissionsExportJob).not_to receive(:new)
      subject
    end
  end

  describe "#assignment" do
    subject { controller.instance_eval { assignment } }
    before { allow(controller).to receive(:params) {{ assignment_id: assignment.id }} }

    it "fetches an assignment by assignment id" do
      expect(Assignment).to receive(:find).with(assignment.id)
      subject
    end

    it "caches the fetch assignment outcome" do
      subject
      expect(Assignment).not_to receive(:find).with(submissions_export.id)
      subject
    end
  end
end
