require "rails_spec_helper"

describe OpenbadgesController, type: :controller do
  let(:user) { create(:user) }

  before(:each) do
    login_user(user)
  end

  context "authorization failed" do
    before { allow(subject).to receive(:params) { params } }

    describe "#connect" do
      let(:subject) { described_class.new }
      let(:params) { { error: "You shall not pass" } }

      it "redirects to the badge url on error" do
        subject.connect
        expect(response).to redirect_to badges_path
      end
    end
  end
end
