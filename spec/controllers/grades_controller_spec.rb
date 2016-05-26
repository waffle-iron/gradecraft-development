require "rails_spec_helper"

describe GradesController do
  include PredictorEventJobsToolkit

  before(:all) do
    @course = create(:course_accepting_groups)
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
      it "creates a grade if none present" do
        assignment = create(:assignment, course: @course)
        expect{get :edit, { assignment_id: assignment.id, student_id: @student.id }}.to change{Grade.count}.by(1)
      end

      it "assigns grade parameters and renders edit" do
        get :edit, { assignment_id: @assignment.id, student_id: @student.id }
        expect(assigns(:assignment)).to eq(@assignment)
        expect(assigns(:student)).to eq(@student)
        expect(assigns(:grade)).to eq(@grade)
        expect(assigns(:title)).to eq("Editing #{@student.name}'s Grade for #{@assignment.name}")
        expect(response).to render_template(:edit)
      end

      context "with additional grade items" do
        it "assigns existing submissions, badges and score levels" do
          assignment = create(:assignment, course: @course)
          submission = create(:submission, student: @student, assignment: assignment)
          badge = create(:badge, course: @course)
          score_level = create(:assignment_score_level, assignment: assignment)

          get :edit, { assignment_id: assignment.id, student_id: @student.id }
          expect(assigns(:submission)).to eq(submission)
          expect(assigns(:badges)).to eq([badge])
          expect(assigns(:assignment_score_levels)).to eq([score_level])
        end
      end

      it "assigns json values for angular use" do
        get :edit, { assignment_id: @assignment.id, student_id: @student.id }
        json = JSON.parse(assigns(:serialized_init_data))
        expect(json).to have_key("grade")
        expect(json).to have_key("badges")
        expect(json).to have_key("assignment")
        expect(json).to have_key("assignment_score_levels")
      end

      it "if rubric present, assigns the rubric and rubric grades" do
        allow(request).to receive(:referer).and_return("http://gradecraft.com/assignments/123")
        assignment = create(:assignment, course: @course)
        rubric = create(:rubric_with_criteria, assignment: assignment)
        criterion = rubric.criteria.first
        level = rubric.criteria.first.levels.first
        criterion_grade = CriterionGrade.create( assignment_id: assignment.id, student_id: @student.id, criterion_id: criterion.id, level_id: level.id)
        get :edit, { id: @grade.id, assignment_id: assignment.id, student_id: @student.id }
        expect(assigns(:rubric)).to eq(rubric)
        expect(JSON.parse(assigns(:criterion_grades))).to eq([{ "id" => criterion_grade.id, "criterion_id" => criterion.id, "level_id" => level.id, "comments" => nil }])
        expect(assigns(:return_path)).to eq("/assignments/123?student_id=#{@student.id}")
      end
    end

    describe "PUT update" do
      it "creates a grade if none present" do
        assignment = create(:assignment, course: @course)
        grade_params = { raw_score: 12345, assignment_id: assignment.id }
        expect{put :update, { assignment_id: assignment.id, student_id: @student.id, grade: grade_params}}.to change{Grade.count}.by(1)
      end

      it "updates the grade" do
        grade_params = { raw_score: 12345, assignment_id: @assignment.id }
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(response).to redirect_to(assignment_path(@grade.reload.assignment))
        expect(@grade.score).to eq(12345)
      end

      it "timestamps the grade" do
        grade_params = { raw_score: 12345, assignment_id: @assignment.id }
        current_time = DateTime.now
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(@grade.reload.graded_at).to be > current_time
      end

      it "attaches the student submission" do
        submission = create :submission, assignment: @assignment, student: @student
        grade_params = { raw_score: 12345,
                         assignment_id: @assignment.id,
                         submission_id: submission.id }
        put :update, { assignment_id: @assignment.id,
                       student_id: @student.id, grade: grade_params }
        grade = Grade.last
        expect(grade.submission).to eq submission
      end

      it "handles a grade file upload" do
        grade_params = { raw_score: 12345, assignment_id: @assignment.id, "grade_files_attributes"=> {"0"=>{"file"=>[fixture_file("test_file.txt", "txt")]}}}

        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect expect(GradeFile.count).to eq(1)
        expect expect(GradeFile.last.filename).to eq("test_file.txt")
      end

      it "handles commas in raw score params" do
        grade_params = { raw_score: "12,345", assignment_id: @assignment.id }
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(response).to redirect_to(assignment_path(@grade.reload.assignment))
        expect(@grade.score).to eq(12345)
      end

      it "handles reverting nil raw score" do
        grade_params = { raw_score: nil, assignment_id: @assignment.id }
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(response).to redirect_to(assignment_path(@grade.reload.assignment))
        expect(@grade.score).to eq(nil)
      end

      it "reverts empty raw score to nil, not zero" do
        grade_params = { raw_score: "", assignment_id: @assignment.id }
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(response).to redirect_to(assignment_path(@grade.reload.assignment))
        expect(@grade.score).to eq(nil)
      end

      it "returns to session if present" do
        session[:return_to] = login_path
        grade_params = { raw_score: 12345, assignment_id: @assignment.id }
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: grade_params}
        expect(response).to redirect_to(login_path)
      end

      it "redirects on failure" do
        allow_any_instance_of(Grade).to receive(:update_attributes).and_return false
        put :update, { assignment_id: @assignment.id, student_id: @student.id, grade: {}}
        expect(response).to redirect_to(edit_assignment_grade_path(@assignment.id, student_id: @student.id))
      end
    end

    describe "earn_student_badges" do
      it "creates new student badges from params" do
        badge_1 = create(:badge)
        badge_2 = create(:badge)
        badge_3 = create(:badge)
        params = {grade_id: @grade.id, earned_badges: [{ badge_id: badge_1.id, student_id: @student },
                                  { badge_id: badge_2.id, student_id: @student },
                                  { badge_id: badge_3.id, student_id: @student }]}
        expect{post :earn_student_badges, params}.to change {EarnedBadge.count}.by(3)
      end
    end

    describe "delete_all_earned_badges"  do
      it "destroys all earned badges for grade" do
        earned_badge_1 = create(:earned_badge, grade: @grade)
        earned_badge_2 = create(:earned_badge, grade: @grade)
        expect{ delete :delete_all_earned_badges, grade_id: @grade.id }.to change {EarnedBadge.count}.by(-2)
        expect(JSON.parse(response.body)).to eq({"message"=>"Earned badges successfully deleted", "success"=>true})
      end

      it "renders error if no badges found to delete" do
        delete :delete_all_earned_badges, {grade_id: @grade.id}
        expect(JSON.parse(response.body)).to eq({"message"=>"Earned badges failed to delete", "success"=>false})
      end
    end

    describe "delete_earned_badge" do

      it "deletes a badge when parameters include id, student id, badge id, and grade id" do
        earned_badge = create(:earned_badge, grade: @grade, student: @student)
        params = {grade_id: @grade.id, student_id: @student.id, badge_id: earned_badge.badge.id, id: earned_badge.id }
        expect{ delete :delete_earned_badge, params }.to change {EarnedBadge.count}.by(-1)
        expect(JSON.parse(response.body)).to eq({"message"=>"Earned badge successfully deleted", "success"=>true})
      end

      it "renders error if no badge found to delete" do
        params = {grade_id: @grade.id, student_id: @student.id, badge_id: 1, id: 1234 }
        delete :delete_earned_badge, params
        expect(JSON.parse(response.body)).to eq({"message"=>"Earned badge failed to delete", "success"=>false})
      end
    end

    describe "POST remove" do
      before do
        allow_any_instance_of(ScoreRecalculatorJob).to \
          receive(:enqueue).and_return true
      end

      it "returns an error message on failure" do
        allow_any_instance_of(Grade).to receive(:save).and_return false
        post :remove, { id: @grade.id }
        expect(response.status).to eq(400)
      end
    end

    describe "POST exclude" do
      before do
        allow_any_instance_of(ScoreRecalculatorJob).to \
          receive(:enqueue).and_return true
      end

      it "marks the Grade as excluded, but preserves the data" do
        @grade.update(
          raw_score: 500,
          feedback: "should be nil",
          feedback_read: true,
          feedback_read_at: Time.now,
          feedback_reviewed: true,
          feedback_reviewed_at: Time.now,
          instructor_modified: true,
          graded_at: DateTime.now,
          status: "Graded"
        )
        post :exclude, { id: @grade }

        @grade.reload
        expect(@grade.excluded_from_course_score).to eq(true)
        expect(@grade.raw_score).to eq(500)
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
          raw_score: 500,
          status: "Graded",
          excluded_from_course_score: true,
          excluded_by_id: 2,
          excluded_at: Time.now
        )
        post :include, { id: @grade }

        @grade.reload
        expect(@grade.excluded_from_course_score).to eq(false)
        expect(@grade.raw_score).to eq(500)
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
        [ Proc.new { get :edit, {grade_id: @grade.id, assignment_id: @assignment.id }},
          Proc.new { get :update, {grade_id: @grade.id, assignment_id: @assignment.id }},
          Proc.new { get :edit, {grade_id: @grade.id, assignment_id: @assignment.id }},
          Proc.new { get :update, {grade_id: @grade.id, assignment_id: @assignment.id }},
          Proc.new { get :remove, { id: @assignment.id, grade_id: @grade.id }},
          Proc.new { delete :destroy, { id: @grade.id }},
        ].each do |protected_route|
          expect(protected_route.call).to redirect_to(:root)
        end
      end
    end
  end
end
