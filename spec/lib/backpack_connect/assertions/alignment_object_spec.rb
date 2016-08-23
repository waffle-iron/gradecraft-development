require "./lib/backpack_connect"

describe BackpackConnect::Assertions::AlignmentObject do
  let(:subject) { BackpackConnect::Assertions::AlignmentObject.new }
  let(:name) { "some_name" }
  let(:url) { "localhost:5000" }
  let(:description) { "test" }

  it "sets values" do
    subject.name = name
    subject.url = url
    subject.description = description
    expect(subject.name).to eq(name)
    expect(subject.url).to eq(url)
    expect(subject.description).to eq(description)
  end
end
