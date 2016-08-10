require "rails_spec_helper"
require "active_record_spec_helper"

describe API::Openbadges::BadgeVerificationController do
  before(:each) { login_user(user) }
  let(:user) { create(:user) }
  let(:badge) { create(:badge) }
  let!(:earned_badge) { create(:earned_badge, badge: badge, student: user) }

  describe "GET #index" do
    context "user does not have the badge" do
      let(:user_2) { create(:user) }
      let(:badge_2) { create(:badge) }
      let(:earned_badge_2) { create(:earned_badge, badge: badge_2, student: user_2 ) }

      it "returns 404 if the user is not found" do
        get :index, format: :json, badge_verification_id: 10, badge_id: earned_badge.id
        expect(response.status).to eq(404)
      end

      it "returns 400 if the user has not earned the badge" do
        get :index, format: :json, badge_verification_id: user.id, badge_id: earned_badge_2.id
        expect(response.status).to eq(400)
      end
    end

    context "user has the badge" do
      let(:earned_badge_id) { badge.id }

      it "returns 200 if the user has earned the badge" do
        get :index, format: :json, badge_verification_id: user.id, badge_id: earned_badge.id
        expect(response.status).to eq(200)
        puts "response body: #{response.body}"
      end
    end
  end
end
