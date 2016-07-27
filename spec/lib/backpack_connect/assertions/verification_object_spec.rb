require "./lib/backpack_connect"

describe BackpackConnect::Assertions::VerificationObject do
  it "initializes with the correct values" do
    options = { type: "hosted", url: "https://www.backpack.com" }
    subject = BackpackConnect::Assertions::VerificationObject.new(options)
    expect(subject.type).to eq options[:type]
    expect(subject.url).to eq options[:url]
  end
end
