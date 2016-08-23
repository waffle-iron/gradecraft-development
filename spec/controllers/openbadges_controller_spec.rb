require "rails_spec_helper"
require "./lib/backpack_connect"

class MockResponse
  attr_reader :code, :parsed_response

  def initialize(code, parsed_response=nil)
    @code = code
    @parsed_response = parsed_response
  end
end

describe OpenbadgesController do
  let(:subject) { described_class.new }
  let(:badge) { create(:badge) }
  let(:earned_badge) { create(:earned_badge, badge: badge, student: user) }
  let(:user) { create(:user) }

  before(:each) do
    login_user(user)
  end

  describe "#connect" do
    context "when authorization returns an error" do
      let(:params) { { error: "You shall not pass", current_badge: 1 } }

      it "should redirect to the earned badge page" do
        get :connect, params.merge(format: :json)
        expect(response).to redirect_to badge_path(params[:current_badge])
      end
    end

    context "when authorization is successful" do
      let(:authenticator) { BackpackConnect::Authenticator.new(params) }
      let(:params) { { expires: DateTime.now, current_badge: earned_badge.id,
        api_root: "localhost:5000", access_token: "secret1",
        refresh_token: "secret2" } }

      it "should set the session variable" do
        get :connect, params.merge(format: :json)
        session_authenticator = session[:backpack_authenticator]
        expect(session_authenticator).not_to be_nil
        authenticator.instance_variables.each do |key|
          expect(session_authenticator.instance_variable_get(key)).to \
            eq(authenticator.instance_variable_get(key))
        end
      end
    end
  end

  describe "#push" do
    context "when not authorized" do
      it "should redirect with status code 401" do
        get :push, id: earned_badge.id
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authorized" do
      let(:authenticator) { BackpackConnect::Authenticator.new(params) }
      let(:params) { { expires: DateTime.now, current_badge: earned_badge.id,
        api_root: "localhost:5000", access_token: "secret1",
        refresh_token: "secret2", id: earned_badge.id } }

      before(:each) do
        session[:backpack_authenticator] = authenticator
      end

      it "should redirect if the earned badge doesn't exist" do
        get :push, id: 2
        expect(response).to redirect_to(badges_path)
      end

      it "should redirect to badges page if successful" do
        allow(HTTParty).to receive(:post).and_return MockResponse.new(200)
        get :push, params.merge(format: :json)
        expect(response).to redirect_to(badge_path(params[:current_badge]))
      end

      it "should redirect with code 401 if unauthorized" do
        allow(HTTParty).to receive(:post).and_return MockResponse.new(401)
        get :push, params.merge(format: :json)
        expect(response).to have_http_status(401)
      end

      it "should redirect to badge page if status code is not 200 or 401" do
        mock_response = MockResponse.new(500, { message: "You have problems" })
        allow(HTTParty).to receive(:post).and_return mock_response
        get :push, params.merge(format: :json)
        expect(response).to redirect_to(badge_path(params[:current_badge]))
      end
    end
  end
end
