require "rails_spec_helper"

describe API::Openbadges::BadgeClassAssertionController do
  let(:subject) { create(:badge) }

  describe "#index" do
    it "returns a badge assertion" do
      get :index, format: :json, id: subject.id
      expect(JSON.parse(response.body)).to eq({"uid" => "whatever"})
    end
  end
end
