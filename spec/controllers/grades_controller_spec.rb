require "rails_spec_helper"
require "grade_proctor"

describe GradesController do
  include PredictorEventJobsToolkit

  before(:all) do
    @course = create(:course)
    @assignment = create(:assignment, course: @course)
    @student = create(:user)
    @student.courses << @course
  end

  before(:each) do
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end

    before (:each) do
      @grade = create(:grade, student: @student, assignment: @assignment, course: @course)
      login_user(@professor)
    end

    after(:each) do
      @grade.delete
    end

    describe "GET show" do
      context "for a group grade" do
        let(:grade) { create :grade, group: group, assignment: assignment,
                        course: @course, student_id: @student.id }
        let(:group) { create :group, course: @course }
        let(:assignment) { create :group_assignment, course: @course }

        before do
          group.assignments << assignment
          group.students << @student
        end

        it "includes the group's name in the title" do
          get :show, id: grade.id
          expect(assigns(:title)).to \
            eq("#{group.name}'s Grade for #{assignment.name}")
        end

        it "renders the template" do
          get :show, id: grade.id
          expect(response).to render_template(:show)
        end
      end

      context "for an individual grade" do
        it "includes the student's name in the title" do
          get :show, id: @grade.id
          expect(assigns(:title)).to \
            eq("#{@student.name}'s Grade for #{@assignment.name}")
        end
      end
    end

    describe "GET edit" do
      it "assigns grade parameters and renders edit" do
        get :edit, { id: @grade.id }
        expect(assigns(:grade)).to eq(@grade)
        expect(assigns(:title)).to \
          eq("Editing #{@grade.student.name}'s Grade for #{@grade.assignment.name}")
        expect(response).to render_template(:edit)
      end

      context "with additional grade items" do
        it "assigns existing submissions, badges and score levels" do
          submission = create(:submission, student: @student, assignment: @assignment)
          badge = create(:badge, course: @course)

          get :edit, { id: @grade.id }
          expect(assigns(:submission)).to eq(submission)
          expect(assigns(:badges)).to eq([badge])
        end
      end
    end

    describe "PUT update" do
      it "updates the grade" do
        put :update, { id: @grade.id, grade: { raw_points: 12345 }}
        expect(@grade.reload.score).to eq(12345)
        expect(response).to redirect_to(assignment_path(@grade.assignment))
      end

      it "timestamps the grade" do
        current_time = DateTime.now
        put :update, { id: @grade.id, grade: { raw_points: 12345 }}
        expect(@grade.reload.graded_at).to be > current_time
      end

      it "marks uses the current user as the graded by id" do
        put :update, { id: @grade.id, grade: { raw_points: 12345 }}

        expect(@grade.reload.graded_by_id).to eq @professor.id
      end

      it "attaches the student submission" do
        submission = create :submission, assignment: @assignment, student: @student
        grade_params = { raw_points: 12345, submission_id: submission.id }
        put :update, { id: @grade.id, grade: grade_params }
        grade = Grade.last
        expect(grade.submission).to eq submission
      end

      it "handles a grade file upload" do
        grade_params = { raw_points: 12345, "grade_files_attributes" => {"0" => {
          "file" => [fixture_file("test_file.txt", "txt")] }}}

        put :update, { id: @grade.id, grade: grade_params}
        expect expect(GradeFile.count).to eq(1)
        expect expect(GradeFile.last.filename).to eq("test_file.txt")
      end

      it "handles commas in raw score params" do
        put :update, { id: @grade.id, grade: { raw_points: "12,345" }}
        expect(@grade.reload.score).to eq(12345)
      end

      it "handles reverting nil raw score" do
        put :update, { id: @grade.id, grade: { raw_points: nil }}
        expect(@grade.reload.score).to eq(nil)
      end

      it "reverts empty raw score to nil, not zero" do
        put :update, { id: @grade.id, grade: { raw_points: "" }}
        expect(@grade.reload.score).to eq(nil)
      end

      context "when grading a series of students" do
        before do
          @next_student = create(
            :student_course_membership, course: @assignment.course,
            user: create(:user, last_name: "Zzz")).user
        end

        it "creates and redirects to grade the next ungraded student when not accepting submissions" do
          @assignment.update(accepts_submissions: false)
          put :update, { id: @grade.id, grade: { raw_points: 12345, status: "Graded"}, redirect_to_next_grade: true}
          expect(response).to redirect_to(edit_grade_path(
            Grade.where(
              student: @next_student,
              assignment: @assignment).first)
          )
        end

        it "creates and redirects to grade the next student with submission" do
          create :submission, assignment: @assignment, student: @student
          create :submission, assignment: @assignment, student: @next_student
          put :update, { id: @grade.id, grade: { raw_points: 12345 }, redirect_to_next_grade: true}
          expect(response).to redirect_to(edit_grade_path(
            Grade.where(
              student: @next_student,
              assignment: @assignment).first)
          )
        end
      end

      it "redirects on failure" do
        allow_any_instance_of(Grade).to receive(:update_attributes).and_return false
        put :update, { id: @grade.id, grade: { full_points: 100 }}
        expect(response).to redirect_to(edit_grade_path(@grade))
      end
    end

    describe "POST remove" do
      before do
        allow_any_instance_of(ScoreRecalculatorJob).to \
          receive(:enqueue).and_return true
      end

      it "returns an error message on failure" do
        allow_any_instance_of(Grade).to receive(:save).and_return false
        post :remove, { id: @grade.id, grade: { full_points: 13 }}
        expect(response.status).to eq(400)
      end

      it "preserves the grade but removes any indication that it was graded" do
        expect_any_instance_of(Grade).to receive(:clear_grade!).and_call_original

        post :remove, { id: @grade.id }
      end

      it "recalculates the grade's score" do
        expect(controller).to receive(:score_recalculator).with(@grade.student)

        post :remove, { id: @grade.id }
      end
    end

    describe "POST exclude" do
      before do
        allow_any_instance_of(ScoreRecalculatorJob).to \
          receive(:enqueue).and_return true
      end

      it "marks the Grade as excluded, but preserves the data" do
        @grade.update(
          raw_points: 500,
          feedback: "should be nil",
          feedback_read: true,
          feedback_read_at: Time.now,
          feedback_reviewed: true,
          feedback_reviewed_at: Time.now,
          graded_at: DateTime.now,
          status: "Graded"
        )
        post :exclude, { id: @grade }

        @grade.reload
        expect(@grade.excluded_from_course_score).to eq(true)
        expect(@grade.raw_points).to eq(500)
        expect(@grade.score).to eq(500)
      end

      it "adds exclusion metadata" do
        current_time = DateTime.now
        post :exclude, { id: @grade }

        @grade.reload
        expect(@grade.excluded_at).to be > current_time
        expect(@grade.excluded_by_id).to eq(@professor.id)
      end

      it "returns an error message on failure" do
        allow_any_instance_of(Grade).to receive(:save).and_return false
        post :exclude, { id: @grade }
        expect(flash[:alert]).to include("grade was not successfully excluded")
      end
    end

    describe "POST inlude" do
      before do
        allow_any_instance_of(ScoreRecalculatorJob).to \
          receive(:enqueue).and_return true
      end

      it "marks the Grade as included, and clears the excluded details" do
        @grade.update(
          raw_points: 500,
          status: "Graded",
          excluded_from_course_score: true,
          excluded_by_id: 2,
          excluded_at: Time.now
        )
        post :include, { id: @grade }

        @grade.reload
        expect(@grade.excluded_from_course_score).to eq(false)
        expect(@grade.raw_points).to eq(500)
        expect(@grade.score).to eq(500)
        expect(@grade.excluded_by_id).to be nil
        expect(@grade.excluded_at).to be nil
      end

      it "returns an error message on failure" do
        allow_any_instance_of(Grade).to receive(:save).and_return false
        post :include, { id: @grade }
        expect(flash[:alert]).to include("grade was not successfully re-added")
      end
    end

    describe "DELETE destroy" do
      it "removes the grade entirely" do
        expect{ delete :destroy, { id: @grade.id }}.to \
          change{Grade.count}.by(-1)
      end

      it "redirects to the assignments if the professor does not have access" do
        allow_any_instance_of(GradeProctor).to \
          receive(:destroyable?).and_return false
        expect(delete :destroy, { id: @grade.id }).to \
          redirect_to(assignment_path(@grade.assignment))
      end
    end

    describe "POST feedback_read" do
      it "should be protected and redirect to root" do
        expect(post :feedback_read, id: @grade.id).to redirect_to(:root)
      end
    end
  end

  context "as student" do
    before do
      @grade = create :grade, student: @student, assignment: @assignment,
        course: @course
      login_user(@student)
      allow(controller).to receive(:current_student).and_return(@student)
    end
    after(:each) { @grade.delete }

    describe "GET show" do
      it "redirects to the assignment show page" do
        get :show, id: @grade.id
        expect(response).to redirect_to(assignment_path(@assignment))
      end
    end

    describe "POST feedback_read" do
      it "marks the grade as read by the student" do
        post :feedback_read, id: @grade.id
        expect(@grade.reload.feedback_read).to be_truthy
        expect(@grade.feedback_read_at).to be_within(1.second).of(Time.now)
        expect(response).to redirect_to assignment_path(@assignment)
      end
    end

    describe "protected routes" do
      before(:all) do
        @group = create(:group)
        @assignment.groups << @group
      end

      it "all redirect to root" do
        [ Proc.new { get :edit, {id: @grade.id }},
          Proc.new { get :update, { id: @grade.id }},
          Proc.new { get :remove, { id: @assignment.id, grade_id: @grade.id }},
          Proc.new { delete :destroy, { id: @grade.id }},
        ].each do |protected_route|
          expect(protected_route.call).to redirect_to(:root)
        end
      end
    end
  end
end
