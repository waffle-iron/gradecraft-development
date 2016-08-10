require_relative "../../app/authenticators/backpack_authenticator"

describe BackpackAuthenticator do
  let(:subject) { described_class.new options }
  let(:options) {{
    error: "none",
    expires: 3600,
    api_root: "https://backpack.openbadges.org/api",
    access_token: "password1",
    refresh_token: "secretrefreshtoken"
  }}

  describe "#initialize" do
    it "sets attribute values for all required keyword arguments" do
      expect(subject).to have_attributes(options)
    end
  end
end
