require "rails_spec_helper"

describe API::Openbadges::BadgeClassController do
  let(:user) { create(:user) }
  let(:subject) { create(:badge) }
  let(:earned_badge) { create(:earned_badge, student: user) }

  before(:each) { login_user(user) }

  describe "#index" do
    context "when the earned badge is not present" do
      it "returns a 401" do
        get :index, format: :json, id: 2
        expect(response).to have_http_status(401)
      end
    end

    context "when the earned badge is present" do
      let(:issuer) { "#{api_openbadges_issuer_organization_index_url}.json" }
      let(:badge_class) { BackpackConnect::Assertions::BadgeClass.new(earned_badge, issuer, request.host_with_port) }
      
      it "returns a badge assertion" do
        get :index, format: :json, id: earned_badge.id
        expect(response.body).to eq(badge_class.to_json)
      end
    end
  end
end
