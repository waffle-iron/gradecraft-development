require "./lib/backpack_connect"
require "active_record_spec_helper"

describe BackpackConnect::Assertions::BadgeClass do
  let(:badge) { build(:badge) }
  let(:issuer) { "https://www.umich.com" }
  let(:host) { "https://www.gradecraft.edu" }

  describe "#initialize" do
    it "initializes with the correct values" do
      subject = BackpackConnect::Assertions::BadgeClass.new(badge, issuer, host)
      expect(subject.name).to eq badge.name
      expect(subject.description).to eq badge.description
      expect(subject.issuer).to eq issuer
      expect(subject.image).to eq "#{host}#{badge.icon}"
    end
  end
end
