require "active_record_spec_helper"

RSpec.describe Classroom::User do
  include SorceryHelper

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

  describe "authentication" do
    let(:password) { "p@ssword" }
    subject { create :user, password: password }

    before { initialize_sorcery_config!(described_class) }

    it "is authenticated if the email and password match" do
      expect(described_class.authenticate subject.email, password).to eq subject
    end

    it "is authenticated with a mixed case email" do
      expect(described_class.authenticate subject.email.upcase, password).to eq subject
    end

    it "is not authenticated if the password does not match" do
      expect(described_class.authenticate subject.email, "blah").to be_nil
    end
  end
end
