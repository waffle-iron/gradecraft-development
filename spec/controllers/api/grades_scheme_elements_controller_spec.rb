require "rails_spec_helper"

describe API::GradeSchemeElementsController do

  describe "GET index" do
    context "with Grade Scheme elements" do
      let(:world) { World.create.with(:course, :student, :grade_scheme_element) }

      before(:each) { login_user(world.student) }

      it "returns grade scheme elements with total points as json" do
        get :index, format: :json
        expect(assigns(:grade_scheme_elements)).to eq([world.grade_scheme_element])
        expect(assigns(:total_points)).to eq(world.grade_scheme_element.low_range)
        expect(response).to render_template(:index)
      end
    end

    context "with no Grade Scheme elements" do
      let(:world) { World.create.with(:course, :assignment, :student) }

      before(:each) { login_user(world.student) }

      it "returns the total points in the course if no grade scheme elements are present" do
        get :index, format: :json
        expect(assigns(:total_points)).to eq(world.assignment.point_total)
      end
    end

    context "with no Grade Scheme elements and no assignments" do
      let(:world) { World.create.with(:course, :student) }

      before(:each) { login_user(world.student) }

      it "returns the total points in the course if no grade scheme elements are present" do
        get :index, format: :json
        expect(assigns(:total_points)).to eq(0)
      end
    end
  end
end
