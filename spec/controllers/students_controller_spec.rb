require "rails_spec_helper"

describe StudentsController do
  before(:all) do
    @course = create(:course)
    @student = create(:user)
    @student.courses << @course
  end
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create \
        user: @professor, course: @course, role: "professor"
    end
    before(:each) { login_user(@professor) }

    describe "GET index" do
      it "returns the students for the current course" do
        get :index
        expect(assigns(:title)).to eq("Player Roster")
        expect(assigns(:students)).to eq([@student])
        expect(response).to render_template(:index)
      end

      it "returns just the students on a team" do
        @team = create(:team, course: @course)
        @student = create(:user)
        @student.courses << @course
        @student.teams << @team
        @student_2 = create(:user)
        @student_2.courses << @course
        get :index, team_id: @team.id
        expect(response).to render_template(:index)
        expect(assigns(:students)).to eq([@student])
      end
    end

    describe "GET show" do
      it "shows the student page" do
        get :show, {id: @student.id}
        expect(response).to render_template(:show)
      end
    end

    describe "GET leaderboard" do
      it "shows the class leaderboard" do
        get :leaderboard
        expect(response).to render_template(:leaderboard)
      end
    end

    describe "GET flagged" do
      before(:each) do
        @student = create(:user)
        @student.courses << @course
        @student_2 = create(:user)
        @student_2.courses << @course
        @flagged_student = create \
          :flagged_user, flagger: @professor, course: @course, flagged: @student
      end

      it "shows the students the current user has flagged" do
        get :flagged
        expect(response).to render_template(:flagged)
        expect(assigns(:students)).to eq([@student])
      end

      it "does not show unflagged students" do
        get :flagged
        expect(response).to render_template(:flagged)
        expect(assigns(:students)).to_not include(@student_2)
      end
    end

    describe "GET syllabus" do
      it "shows the class syllabus" do
        get :syllabus, id: 10
        expect(response).to render_template(:syllabus)
      end
    end

    describe "GET timeline" do
      it "shows the course timeline" do
        get :timeline, id: 10
        expect(response).to render_template(:timeline)
      end
    end

    describe "GET autocomplete_student_name" do
      it "provides a list of all students and their ids" do
        get :autocomplete_student_name, id: 10
        (expect(response.status).to eq(200))
      end
    end

    describe "GET course_progress" do
      it "shows the course progress" do
        get :course_progress, id: 10
        expect(assigns(:title)).to eq("Your Course Progress")
        expect(response).to render_template(:course_progress)
      end
    end

    describe "GET predictor" do
      it "shows the grade predictor page" do
        get :predictor, id: 10
        expect(response).to render_template(:predictor)
      end
    end

    describe "GET grade_index" do
      it "shows the grade index page" do
        get :grade_index, student_id: @student.id
        allow(StudentsController).to \
          receive(:current_student).and_return(@student)
        expect(response).to render_template(:grade_index)
      end
    end

    describe "GET recalculate" do
      it "triggers the recalculation of a student's grade" do
        get :recalculate, { student_id: @student.id }
        expect(response).to redirect_to(student_path(@student))
      end
    end

    describe "GET teams" do
      it "shows the team page shown to students" do
        get :teams, student_id: @student.id
        expect(response).to render_template(:teams)
      end
    end
  end

  context "as a student" do
    before { login_user(@student) }

    describe "GET syllabus" do
      it "shows the class syllabus" do
        get :syllabus
        expect(response).to render_template(:syllabus)
      end
    end

    describe "GET timeline" do
      it "shows the course timeline" do
        get :timeline, id: 10
        expect(response).to redirect_to(dashboard_path)
      end
    end

    describe "GET course_progress" do
      it "shows the course progress" do
        get :course_progress, id: 10
        expect(assigns(:title)).to eq("Your Course Progress")
        expect(response).to render_template(:course_progress)
      end
    end

    describe "GET predictor" do
      it "shows the grade predictor page" do
        get :predictor, id: 10
        expect(response).to render_template(:predictor)
      end
    end

    describe "GET teams" do
      it "shows the team page shown to students" do
        get :teams
        expect(response).to render_template(:teams)
      end
    end

    describe "protected routes" do
      [
        :index,
        :leaderboard,
        :autocomplete_student_name,
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :grade_index,
        :recalculate
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {student_id: "10"}).to redirect_to(:root)
        end
      end
    end

    describe "protected routes requiring id in params" do
      [
        :show
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {id: "10"}).to redirect_to(:root)
        end
      end
    end
  end
end
