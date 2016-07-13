require "rails_spec_helper"

describe API::BackpackConnectController do
  describe "GET connect" do
    it "gets the parameters back from the backpack connect callback" do
      get :connect, format: :json
    end
  end
end
