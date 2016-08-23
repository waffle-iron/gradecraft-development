require "rails_spec_helper"

describe API::Openbadges::IssuerOrganizationController do
  let(:user) { create(:user) }

  before(:each) { login_user(user) }

  describe "#index" do
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
