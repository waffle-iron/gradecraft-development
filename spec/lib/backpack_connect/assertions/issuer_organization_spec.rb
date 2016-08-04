require "./lib/backpack_connect"

describe BackpackConnect::Assertions::IssuerOrganization do
  describe "#initialize" do
    let(:options) {{
      name: "Umich",
      url: "https://www.umich.edu",
      description: "University of Michigan",
      image: "logo.png",
      email: "mail@umich.edu",
      revocationList: [ "1", "2", "3" ]
    }}

    it "sets the correct values" do
      subject = BackpackConnect::Assertions::IssuerOrganization.new(options)
      expect(subject).to have_attributes(options)
    end
  end
end
