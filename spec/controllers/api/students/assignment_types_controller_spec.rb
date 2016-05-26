require "rails_spec_helper"

describe API::Students::AssignmentTypesController do
  let(:world) { World.create.with(:course, :assignment, :student) }
  let(:assignment_type) { world.assignment.assignment_type }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  before do
    login_user(professor)
  end

  describe "GET index" do
    it "returns assignment types as json with current student if id present" do
      get :index, format: :json, student_id: world.student.id
      expect(assigns(:student)).to eq(world.student)
      expect(assigns(:assignment_types)).to eq([assignment_type])
      expect(assigns(:update_weights)).to be_falsey
      expect(response).to render_template("api/assignment_types/index")
    end
  end
end
