require "rails_spec_helper"

describe API::BadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }

  before(:each) { login_user(world.student) }

  describe "GET index" do
    it "returns badges for the current course" do
      get :index, format: :json
      expect(assigns(:badges)).to eq([world.badge])
      expect(response).to render_template(:index)
    end
  end
end
