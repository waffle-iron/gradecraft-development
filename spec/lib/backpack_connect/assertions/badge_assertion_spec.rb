require "./lib/backpack_connect"
require "active_record_spec_helper"

describe BackpackConnect::Assertions::BadgeAssertion do
  let(:badge) { create(:badge) }
  let(:user) { build(:user) }
  let(:verification) {{ type: "hosted", url: "/api/verification/123" }}
  let(:badgeUrl) { "/api/badge_class_assertion/#{badge.id}" }

  it "initializes with the correct values" do
    subject = BackpackConnect::Assertions::BadgeAssertion.new(badge, user, badgeUrl, verification)
    expect(subject.uid).to eq badge.id
  end
end
