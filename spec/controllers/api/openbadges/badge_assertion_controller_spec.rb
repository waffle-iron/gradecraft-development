require "rails_spec_helper"

describe API::Openbadges::BadgeAssertionController do
  let(:user) { create(:user) }
  let(:earned_badge) { create :earned_badge, student: user }

  before(:each) { login_user(user) }

  describe "#index" do
    context "when the user has not earned the badge" do
      it "returns 404" do
        get :index, id: 2
        expect(response.status).to eq(404)
        expect(response.body).to eq({ message: "Current user has not earned this badge" }.to_json)
      end
    end

    context "when the user has earned the badge" do
      it "returns 200" do
        get :index, id: earned_badge.id
        expect(response.status).to eq(200)
      end
    end
  end
end
