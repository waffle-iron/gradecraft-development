require "active_record_spec_helper"

RSpec.describe Classroom::User do
  describe "validations" do
    subject { build :user }

    it "requires an email address" do
      subject.email = ""

      expect(subject).to_not be_valid
      expect(subject.errors[:email]).to include "can't be blank"
    end
  end
end
