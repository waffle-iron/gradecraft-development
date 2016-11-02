require "rails_spec_helper"
require "api_spec_helper"

describe Grades::ImportersController do
  let(:world) { World.create.with(:course, :assignment, :student, :grade) }
  before { allow(controller).to receive(:current_course).and_return world.course }

  context "as a professor" do
    let(:membership) { create :professor_course_membership, course: world.course }
    let(:professor) { membership.user }

    before { login_user professor }

    describe "GET download" do
      it "returns sample csv data" do
        get :download, params: { assignment_id: world.assignment.id, importer_provider_id: :csv }, format: :csv

        expect(response.body).to \
          include("First Name,Last Name,Email,Score,Feedback")
      end
    end

    describe "POST upload" do
      render_views

      let(:file) { fixture_file "grades.csv", "text/csv" }

      it "renders the results from the import" do
        world.student.reload.update_attribute :email, "robert@example.com"
        second_student = create(:user, username: "jimmy")
        second_student.courses << world.course

        post :upload, params: { assignment_id: world.assignment.id, importer_provider_id: :csv, file: file }

        expect(response).to render_template :import_results
        expect(response.body).to include "2 Grades Imported Successfully"
      end

      it "enqueues the resque job to update the grades" do
        world.student.reload.update_attribute :email, "robert@example.com"
        second_student = create(:user, username: "jimmy")
        second_student.courses << world.course
        ResqueSpec.reset!

        post :upload, params: { assignment_id: world.assignment.id, importer_provider_id: :csv, file: file }

        expect(GradeUpdaterJob).to have_queue_size_of(2)
      end

      context "with students that are not part of the current course" do
        it "renders any errors that have occured" do
          post :upload, params: { assignment_id: world.assignment.id, importer_provider_id: :csv, file: file }

          expect(response.body).to include "3 Grades Not Imported"
          expect(response.body).to include "Student not found in course"
        end
      end

      context "without a file to import with" do
        it "renders the missing file error" do
          post :upload, params: { assignment_id: world.assignment.id, importer_provider_id: :csv }

          expect(flash[:notice]).to eq("File is missing")
          expect(response).to redirect_to(assignment_grades_importer_path(world.assignment, :csv))
        end
      end
    end

    describe "GET grades" do
      let(:access_token) { "BLAH" }

      before do
        UserAuthorization.create user: professor,
          provider: :canvas, access_token: access_token, refresh_token: "BLAH",
          expires_at: 2.days.from_now
        WebMock.disable_net_connect!(allow_localhost: true)
      end
      after { WebMock.allow_net_connect! }

      context "unable to connect to Canvas" do
        it "redirects back to the importers selection" do
          stub_request(:get,
                       "https://umich-dev.instructure.com/api/v1/courses/123/assignments/")
            .with(query: { "access_token" => access_token })
            .to_raise(JSON::ParserError)

          get :grades, params: { assignment_id: world.assignment.id,
                                 importer_provider_id: :canvas,
                                 id: "123" }

          expect(flash[:alert]).to eq \
            "There was an issue trying to retrieve the assignment from Canvas."
          expect(response).to redirect_to assignment_grades_importers_path(world.assignment)
        end
      end
    end

    describe "POST grades_import" do
      let(:access_token) { "BLAH" }
      let(:assignment_ids) { ["ASSIGNMENT_1"] }
      let(:course_id) { "COURSE_ID" }
      let(:grade_ids) { ["GRADE1", "GRADE2"] }
      let(:result) { double(:result, success?: true, message: "") }
      let!(:user_authorization) do
        create :user_authorization, :canvas, user: professor, access_token: access_token,
          expires_at: 2.days.from_now
      end

      before do
        allow(Services::ImportsLMSGrades).to receive(:import).and_return result
      end

      it "imports the selected grades" do
        expect(Services::ImportsLMSGrades).to \
          receive(:import).with("canvas", access_token, course_id,
                                assignment_ids, grade_ids, world.assignment,
                                professor)
            .and_return result

        post :grades_import, params: { importer_provider_id: "canvas",
          assignment_id: world.assignment.id, id: course_id, grade_ids: grade_ids,
          assignment_ids: assignment_ids }
      end

      it "renders the results" do
        post :grades_import, params: { importer_provider_id: "canvas",
          assignment_id: world.assignment.id, id: course_id, grade_ids: grade_ids,
          assignment_ids: assignment_ids }

        expect(response).to render_template :grades_import_results
      end

      context "with an invalid result" do
        it "re-renders the template with the error" do
          allow(result).to receive(:success?).and_return false
          syllabus = double(course: {}, grades: [])
          allow(controller).to receive(:syllabus).and_return syllabus

          post :grades_import, params: { importer_provider_id: "canvas",
            assignment_id: world.assignment.id, id: course_id, grade_ids: grade_ids,
            assignment_ids: assignment_ids }

          expect(response).to render_template :grades
        end
      end
    end
  end

  context "as a student" do
    before { login_user world.student }

    describe "GET download" do
      it "redirects back to the root" do
        expect(get :download, params: { assignment_id: world.assignment.id, importer_provider_id: :csv }).to \
          redirect_to(:root)
      end
    end

    describe "GET show" do
      it "redirects back to the root" do
        expect(get :show, params: { assignment_id: world.assignment.id, provider_id: :csv }).to \
          redirect_to(:root)
      end
    end

    describe "POST upload" do
      it "redirects back to the root" do
        expect(post :upload, params: { assignment_id: world.assignment.id, importer_provider_id: :csv }).to \
          redirect_to(:root)
      end
    end
  end
end
