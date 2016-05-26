require "rails_spec_helper"

describe GradeSchemeElementsController do
  before(:all) { @course = create(:course) }
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end

    before(:each) do
      @grade_scheme_element = create(:grade_scheme_element, course: @course)
      login_user(@professor)
    end

    describe "GET index" do
      it "assigns all grade scheme elements" do
        get :index
        expect(assigns(:grade_scheme_elements)).to eq([@grade_scheme_element])
      end
    end

    describe "GET mass_edit" do
      it "shows the mass edit form" do
        get :mass_edit
        expect(assigns(:grade_scheme_elements)).to eq(@course.grade_scheme_elements)
      end
    end

    describe "PUT mass_update" do
      it "updates the grade scheme elements all at once" do
        params = { "grade_scheme_elements_attributes" => [{ id: @grade_scheme_element.id, letter: "C", level: "Sea Slug", low_range: 0, high_range: 100000, course_id: @course.id }, { id: GradeSchemeElement.new.id, letter: "B", level: "Snail",
          low_range: 100001, high_range: 200000, course_id: @course.id }],
        "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params.merge(format: :json)
        expect(@course.reload.grade_scheme_elements.count).to eq(2)
        expect(@grade_scheme_element.reload.level).to eq("Sea Slug")
      end

      it "does not save the changes if invalid" do
        @grade_scheme_element_2 = create(:grade_scheme_element, course: @course)
        params = { "grade_scheme_elements_attributes" => [{ id: @grade_scheme_element.id, letter: "C", level: "Sea Slugs Galore", low_range: 0, high_range: 100010, course_id: @course.id }, { id: GradeSchemeElement.new.id, letter: "B", level: "Snail",
          low_range: 100011, high_range: nil, course_id: @course.id}],
        "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params.merge(format: :json)
        expect(@grade_scheme_element.reload.high_range).to eq(100000)
        expect(response.status).to eq(500)
      end
    end
  end

  context "as student" do
    before(:all) do
      @student = create(:user)
      @student.courses << @course
    end
    before(:each) do
      login_user(@student)
    end

    describe "protected routes" do
      [
        :index,
        :mass_edit,
        :mass_update
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end
  end
end
