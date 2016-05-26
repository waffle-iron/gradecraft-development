require "rails_spec_helper"

describe RubricsController do
  before(:all) { @course = create(:course) }
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
      @assignment = create(:assignment, course: @course)
    end

    before do
      @rubric = create(:rubric, assignment: @assignment)
      login_user(@professor)
    end

    describe "GET design" do
      it "shows the design form" do
        get :design, { assignment_id: @assignment.id, rubric: @rubric}
        expect(assigns(:title)).to eq("Design Rubric for #{@assignment.name}")
        expect(response).to render_template(:design)
      end
    end

    describe "GET export" do
      it "retrieves the export download" do
        get :export, assignment_id: @assignment.id, format: :csv
        expect(response.body).to include("Criteria ID,Criteria Description")
      end
    end
  end

  context "as a student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
    end
    before(:each) { login_user(@student) }

    describe "protected routes" do
      [
        :design,
        :create,
        :destroy,
        :update
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route, {assignment_id: 1, id: "1"}).to redirect_to(:root)
          end
        end
    end
  end
end
