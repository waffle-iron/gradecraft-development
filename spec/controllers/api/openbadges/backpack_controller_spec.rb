require "rails_spec_helper"
require "active_record_spec_helper"

describe API::Openbadges::BackpackController do
  let(:badge) { create(:badge) }
  let(:student) { build(:user) }
  let(:earned_badge) { create(:earned_badge, badge: badge, student: student) }
  let(:authenticator) { BackpackConnect::Authenticator.new({
    error: nil,
    expires: 3600,
    api_root: "https://backpack.openbadges.org/api",
    access_token: "password1",
    refresh_token: "secretrefreshtoken"
  })}

  context "as a student" do
    before(:each) do
      login_user(student)
      allow(controller).to receive(:current_user).and_return(student)
    end

    describe "#issue" do
      context "is not authorized" do
        it "returns 401" do
          get :issue, format: :json, id: 2
          expect(response.status).to eq(401)
          expect(JSON.parse(response.body)).to eq({ "message" => "Not authorized" })
        end
      end

      context "is authorized" do
        before(:each) do
          request.session[:backpack_authenticator] = authenticator
        end

        it "returns 400 if the user has not earned the badge" do
          get :issue, format: :json, id: 2
          expect(response.status).to eq(400)
          expect(JSON.parse(response.body)).to eq({ "message" => "Current user has not earned this badge" })
        end
      end
    end
  end
end
