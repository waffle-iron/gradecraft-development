require "./lib/backpack_connect"

describe BackpackConnect::Assertions::IdentityObject do
  it "initializes with the correct values" do
    options = { identity: "student@umich.edu", type: "email", hashed: true, salt: "secure123" }
    subject = BackpackConnect::Assertions::IdentityObject.new(options)
    expect(subject.identity).to eq options[:identity]
    expect(subject.type).to eq options[:type]
    expect(subject.hashed).to eq options[:hashed]
    expect(subject.salt).to eq options[:salt]
  end
end
