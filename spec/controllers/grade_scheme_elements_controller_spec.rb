require "rails_spec_helper"

describe GradeSchemeElementsController do
  let(:course) { create(:course) }

  context "as professor" do
    let!(:course_membership) { create(:student_course_membership, course: course, score: 100000,
      earned_grade_scheme_element_id: grade_scheme_element.id) }
    let!(:another_course_membership) { create(:student_course_membership, course: course, score: 80000,
      earned_grade_scheme_element_id: grade_scheme_element.id) }
    let(:professor) { create(:professor_course_membership, course: course).user }
    let(:grade_scheme_element) { create(:grade_scheme_element, letter: "A", course: course) }

    before(:each) do
      login_user(professor)
      allow(controller).to receive(:current_course).and_return course
    end

    describe "GET index" do
      it "assigns all grade scheme elements" do
        get :index
        expect(assigns(:grade_scheme_elements)).to eq([grade_scheme_element])
      end
    end

    describe "GET edit" do
      it "renders the edit grade scheme form" do
        get :edit, params: { id: grade_scheme_element.id }
        expect(assigns(:grade_scheme_element)).to eq(grade_scheme_element)
        expect(response).to render_template(:edit)
      end
    end

    describe "PUT update" do
      it "updates the grade scheme element" do
        grade_scheme_element_params = { letter: "B" }
        put :update, params: { id: grade_scheme_element.id, grade_scheme_element: grade_scheme_element_params }
        expect(grade_scheme_element.reload.letter).to eq("B")
      end
    end

    describe "GET mass_edit" do
      it "shows the mass edit form" do
        get :mass_edit
        expect(assigns(:grade_scheme_elements)).to eq(course.grade_scheme_elements)
      end
    end

    describe "PUT mass_update" do
      it "updates the grade scheme elements all at once" do
        params = { "grade_scheme_elements_attributes" => [{
          id: grade_scheme_element.id, letter: "C", level: "Sea Slug", lowest_points: 0,
          highest_points: 100000, course_id: course.id }, { id: GradeSchemeElement.new.id,
          letter: "B", level: "Snail", lowest_points: 100001, highest_points: 200000,
          course_id: course.id }], "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params: params, format: :json
        expect(course.reload.grade_scheme_elements.count).to eq(2)
        expect(grade_scheme_element.reload.level).to eq("Sea Slug")
      end

      it "does not save the changes if invalid" do
        grade_scheme_element_2 = create(:grade_scheme_element, course: course)
        params = { "grade_scheme_elements_attributes" => [{
          id: grade_scheme_element.id, letter: "C", level: "Sea Slugs Galore", lowest_points: 0,
          highest_points: 100010, course_id: course.id }, { id: GradeSchemeElement.new.id,
          letter: "B", level: "Snail", lowest_points: 100011, highest_points: nil,
          course_id: course.id}], "deleted_ids"=>nil, "grade_scheme_element"=>{} }
        put :mass_update, params: params, format: :json
        expect(grade_scheme_element.reload.highest_points).to eq(100000)
        expect(response.status).to eq(500)
      end
    end

    it "recalculates scores for all students in the course" do
      params = { "grade_scheme_elements_attributes" => [{
        id: grade_scheme_element.id, letter: "C", level: "Sea Slug", lowest_points: 0,
        highest_points: 100000, course_id: course.id }, { id: GradeSchemeElement.new.id,
        letter: "B", level: "Snail", lowest_points: 100001, highest_points: 200000,
        course_id: course.id }], "deleted_ids"=>nil, "grade_scheme_element"=>{} }
      expect{ put :mass_update, params: params, format: :json }.to change { queue(ScoreRecalculatorJob).size }.by(course.students.count)
    end

    describe "GET export_structure" do
      it "retrieves the export_structure download" do
        get :export_structure, params: { id: course.id }, format: :csv
        expect(response.body).to include("Level ID,Letter Grade,Level Name,Lowest Points,Highest Points")
      end
    end
  end

  context "as student" do
    let(:student) { create(:student_course_membership, course: course).user }

    before(:each) do
      login_user(student)
    end

    describe "GET index" do
      it "assigns all grade scheme elements" do
        grade_scheme_element = create(:grade_scheme_element, letter: "A", course: course)
        get :index
        expect(assigns(:grade_scheme_elements)).to eq([grade_scheme_element])
      end
    end

    describe "protected routes" do
      [
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
