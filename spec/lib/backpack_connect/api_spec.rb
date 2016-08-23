require "api_spec_helper"
require "active_record_spec_helper"
require "./lib/backpack_connect"

describe BackpackConnect::API, type: :disable_external_api do
  let(:badge) { build :badge }
  let(:user) { create :user }
  let(:assertion) { BackpackConnect::Assertions::BadgeAssertion.new(badge, user, "http://badge.com", {}) }
  let(:authenticator) { BackpackConnect::Authenticator.new({
    error: nil,
    expires: 3600,
    api_root: "https://backpack.openbadges.org/api",
    access_token: "password1",
    refresh_token: "secretrefreshtoken" })}

  describe "#initialize" do
    it "sets the authenticator" do
      expect(described_class.new(authenticator).authenticator).to eq authenticator
    end
  end

  describe "#issue" do
    context "when not authorized" do
      let(:subject) { described_class.new(nil) }

      it "throws an exception if the user has not yet granted permission to the backpack" do
        expect { subject.issue assertion }.to \
          raise_error Exception, "User has not granted permissions to export badges"
      end
    end

    context "when authorized" do
      let(:subject) { described_class.new(authenticator) }

      it "requests from the specified path" do
        stub = stub_request(:post, "https://backpack.openbadges.org/api/issue").
          with(:body => assertion.to_json, :headers => { "Content-Type" => "application/json" }).
          to_return(:status => 200, :body => "", :headers => {})
        subject.issue assertion
        expect(stub).to have_been_requested
      end
    end
  end
end
