require "api_spec_helper"
require "active_record_spec_helper"
require "./lib/backpack_connect"
#this should probably be a part of the module but it doesn't seem to work

describe BackpackConnect::API, type: :disable_external_api do
  let(:badge) { build :badge }
  let(:authenticator) { Authenticator.new(
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

    # context "with authorization" do
    #   let(:subject) { described_class.new(authenticator) }
    #
    #   it "requests from the specified path" do
    #     stub = stub_request(:get, "https://backpack.openbadges.org/api/issue")
    #       .to_return(status: 200, body: {}.to_json, headers: {})
    #     subject.issue(badge)
    #     expect(stub).to have_been_requested
    #   end
    #
    #   it "allows for parameters" do
    #     stub = stub_request(:get, "https://backpack.openbadges.org/api/issue")
    #       .with(query: { "uid" => "123456" })
    #       .to_return(status: 200, body: {}.to_json, headers: {})
    #     subject.issue(badge, { uid: "123456" })
    #     expect(stub).to have_been_requested
    #   end
    #
    #   it "does magical badgery stuff" do
    #     body = { Message: "Badge successfully issued" }
    #     stub = stub_request(:get, "https://backpack.openbadges.org/api/issue")
    #       .with(query: { "uid" => "123456" })
    #       .to_return(status: 200, body: body.to_json, headers: {})
    #     expect(subject.issue(badge)).to eq body.to_json
    #   end
    # end
  end
end
