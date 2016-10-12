require "active_record_spec_helper"

RSpec.describe Classroom::User do
  describe "validations" do
    subject { build :user }

    it "requires an email address" do
      subject.email = ""

      expect(subject).to_not be_valid
      expect(subject.errors[:email]).to include "can't be blank"
    end

    it "requires a valid email address" do
      subject.email = "blah@example"

      expect(subject).to_not be_valid
      expect(subject.errors[:email]).to include "is invalid"
    end

    it "requires a unique email address" do
      create :user, email: subject.email.upcase

      expect(subject).to_not be_valid
      expect(subject.errors[:email]).to include "has already been taken"
    end
  end
end
