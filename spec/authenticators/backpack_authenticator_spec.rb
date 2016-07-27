require_relative "../../app/authenticators/backpack_authenticator"

describe BackpackAuthenticator do
  subject { described_class.new authenticator_options }

  let(:authenticator_options) do
    {
      error: nil,
      expires: 3600,
      api_root: "https://backpack.openbadges.org/api",
      access_token: "password1",
      refresh_token: "secretrefreshtoken"
    }
  end

  describe "#initialize" do
    it "sets attribute values for all required keyword arguments" do
      expect(subject.error).to eq nil
      expect(subject.expires).to eq 3600
      expect(subject.api_root).to eq "https://backpack.openbadges.org/api"
      expect(subject.access_token).to eq "password1"
      expect(subject.refresh_token).to eq "secretrefreshtoken"
    end
  end
end
