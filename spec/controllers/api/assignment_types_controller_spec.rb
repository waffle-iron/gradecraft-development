require "rails_spec_helper"

describe API::AssignmentTypesController do
  let(:world) { World.create.with(:course, :assignment, :student) }
  let(:assignment_type) { world.assignment.assignment_type }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as a professor" do
    before do
      login_user(professor)
    end

    describe "GET index" do
      it "returns assignment types with null student" do
        get :index, format: :json
        expect(assigns(:student).class).to eq(NullStudent)
        expect(assigns(:assignment_types)).to eq([assignment_type])
        expect(assigns(:update_weights)).to be_falsey
        expect(response).to render_template(:index)
      end
    end
  end

  context "as a student" do
    before do
      login_user(world.student)
    end

    describe "GET index" do
      it "returns badges for the current course" do
        get :index, format: :json
        expect(assigns(:student)).to eq(world.student)
        expect(assigns(:assignment_types)).to eq([assignment_type])
        expect(assigns(:update_weights)).to be_truthy
        expect(response).to render_template(:index)
      end
    end
  end
end

