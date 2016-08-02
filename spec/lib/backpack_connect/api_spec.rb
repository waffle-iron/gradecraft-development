require "api_spec_helper"
require "active_record_spec_helper"
require "./lib/backpack_connect"
require "./app/authenticators/backpack_authenticator"
#this should probably be a part of the module but it doesn't seem to work

describe BackpackConnect::API, type: :disable_external_api do
  let(:badge) { build :badge }
  let(:authenticator) { BackpackAuthenticator.new(
    error: nil,
    expires: 3600,
    api_root: "https://backpack.openbadges.org/api",
    access_token: "password1",
    refresh_token: "secretrefreshtoken" )}

  describe "#initialize" do
    it "sets the authenticator" do
      expect(described_class.new(authenticator).authenticator).to eq authenticator
    end
  end

  describe "#issue the badge" do
    context "without authorization" do
      it "fails if the user has not yet granted permission to the backpack" do
        subject = described_class.new(nil)
        expect { subject.issue(badge) }.to \
          raise_error SecurityError, "User has not granted permissions to export badges"
      end
    end

    context "with authorization" do
      let(:subject) { described_class.new(authenticator) }
      let(:assertion) { BackpackConnect::Assertions::BadgeClass.new(badge) }

      it "requests from the specified path" do
        stub = stub_request(:post, "https://backpack.openbadges.org/api/issue").
          with(:body => { badge: assertion }.to_json, :headers => { 'Content-Type' => 'application/json' }).
          to_return(:status => 200, :body => "", :headers => {})
        subject.issue(assertion)
        expect(stub).to have_been_requested
      end
    end
  end
end
