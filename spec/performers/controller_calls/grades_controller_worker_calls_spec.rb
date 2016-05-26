require "rails_spec_helper"
require "set"

include ResqueJobSharedExamplesToolkit

RSpec.describe GradesController, type: :controller, background_job: true do
  include InQueueHelper

  let(:course) { create(:course_accepting_groups) }
  let(:assignment) { create(:assignment, course_id: course.id) }
  let(:job_attributes) {{ grade_id: grade.id }} # for GradeUpdaterJob calls
  let(:grade_attributes) {{ course_id: course.id, student_id: student.id, assignment_id: assignment.id }}
  let(:grade) { create(:grade, grade_attributes) }

  let(:student) { create(:user) }
  let(:professor) { create(:user) }
  let(:enroll_professor) { CourseMembership.create(user_id: professor.id, course_id: course.id, role: "professor") }

  before(:each) { ResqueSpec.reset! }

  describe "triggering jobs as a professor" do
    before(:each) { enroll_and_login_professor }

    describe "#update" do
      let(:request_attrs) {{ assignment_id: assignment.id, grade: { raw_score: 50 } }}
      subject { put :update, request_attrs }

      before do
        allow(Grade).to receive(:find_or_create).and_return grade
      end

      context "grade attributes are successfully updated" do
        before { allow(grade).to receive(:update_attributes) { true } }

        context "grade is released" do
          let(:grade) { create(:released_grade, grade_attributes) }

          before do
            allow(grade).to receive(:is_released?) { true }
          end

          it_behaves_like "a successful resque job", GradeUpdaterJob
        end

        context "grade has not been released" do
          before { allow(grade).to receive(:is_released?) { false } }

          it_behaves_like "a failed resque job", GradeUpdaterJob
        end
      end

      context "grade attributes fail to update" do
        before { allow(grade).to receive(:update_attributes) { false } }

        it_behaves_like "a failed resque job", GradeUpdaterJob
      end
    end

    describe "actions that trigger multiple GradeUpdaterJob instances" do
      let(:student2) { create(:user) }
      let(:students) { [student, student2] }
      let(:grade2) { create(:grade, grade_attributes.merge(student_id: student2.id)) }
      let(:grades) { [grade, grade2] }
      let(:grade_ids) { [grade.id, grade2.id] }

      describe "PUT #update_status" do
        subject { put :update_status, request_attrs }
        before { enroll_and_login_professor }

        context "params[:file] is present" do
          let(:request_attrs) {{ id: assignment.id, grade_ids: grade_ids }}
          before { allow(controller).to receive_messages(update_status_grade_ids: grade_ids) }
        end
      end

    end
  end

  def enroll_and_login_professor
    allow(controller).to receive_messages(current_student: student)
    enroll_professor
    login_user(professor)
    session[:course_id] = course.id
  end
end
