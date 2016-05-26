require "active_record_spec_helper"
require_relative "../../app/authenticators/secure_token_authenticator"

describe SecureTokenAuthenticator do
  subject { described_class.new authenticator_options }

  let(:authenticator_options) do
    {
      secure_token_uuid: "some_uuid",
      secret_key: "skeletonkeysrsly",
      target_class: "WaffleClass",
      target_id: "8",
    }
  end

  let(:secure_token) { SecureToken.new }

  describe "#initialize" do
    it "sets attribute values for all required keyword arguments" do
      expect(subject.secure_token_uuid).to eq "some_uuid"
      expect(subject.secret_key).to eq "skeletonkeysrsly"
      expect(subject.target_class).to eq "WaffleClass"
      expect(subject.target_id).to eq "8"
    end

    it "sets an attribute value for keyword arguments" do
      expect(subject.slowdown_duration).to eq 1
    end
  end

  describe "accessible attributes" do
    it "has an accessible uuid" do
      subject.secure_token_uuid = "great"
      expect(subject.secure_token_uuid).to eq("great")
    end

    it "has an accessible target class" do
      subject.target_class = "GreatClass"
      expect(subject.target_class).to eq("GreatClass")
    end

    it "has an accessible target id" do
      subject.target_id = 9
      expect(subject.target_id).to eq(9)
    end

    it "has an accessible secret_key" do
      subject.secret_key = "the-secret-key"
      expect(subject.secret_key).to eq("the-secret-key")
    end

    it "has an accessible slowdown_duration" do
      subject.slowdown_duration = 10
      expect(subject.slowdown_duration).to eq 10
    end
  end

  describe "#authenticates?" do
    let(:result) { subject.authenticates? }
    let(:secure_token) { SecureToken.new }

    before(:each) do
      allow(subject).to receive_messages(
        uuid_format_valid?: true,
        secure_key_format_valid?: true,
        secure_token: secure_token,
        secret_key: "the-secret-key"
      )

      allow(secure_token).to receive(:unlocked_by?)
        .with("the-secret-key").and_return true
      allow(secure_token).to receive(:expired?) { false }
    end

    context "all steps return true" do
      it "authenticates" do
        expect(result).to be_truthy
      end
    end

    context "the uuid format is not valid" do
      it "does not authenticate" do
        allow(subject).to receive(:uuid_format_valid?) { false }
        expect(result).to be_falsey
      end
    end

    context "the secure key format is not valid" do
      it "does not authenticate" do
        allow(subject).to receive(:secure_key_format_valid?) { false }
        expect(result).to be_falsey
      end
    end

    context "the secure token isn't present" do
      it "does not authenticate" do
        allow(subject).to receive(:secure_token) { nil }
        expect(result).to be_falsey
      end
    end

    context "the secure token exists but is expired" do
      it "does not authenticate" do
        allow(secure_token).to receive(:expired?) { true }
        expect(result).to be_falsey
      end
    end

    context "the secure token isn't unlocked by the given secret key" do
      before(:each) do
        allow(secure_token).to receive(:unlocked_by?)
          .with("the-secret-key").and_return false
      end

      it "does not authenticate" do
        expect(result).to be_falsey
      end
    end
  end

  describe "#valid_token_expired?" do
    let(:result) { subject.valid_token_expired? }

    before(:each) do
      allow(subject).to receive(:secure_token) { secure_token }
    end

    context "no secure token exists" do
      let(:secure_token) { nil }

      it "returns nil" do
        expect(result).to eq false
      end
    end

    context "a secure token exists" do
      context "the secure token is not expired" do
        it "returns false" do
          allow(secure_token).to receive(:expired?) { false }
          expect(result).to be_falsey
        end
      end

      context "the secure token is expired" do
        it "returns true" do
          allow(secure_token).to receive(:expired?) { true }
          expect(result).to be_truthy
        end
      end
    end
  end

  describe "#secure_token" do
    let(:result) { subject.secure_token }

    context "a secure token exists with the uuid and target class" do
      let(:authenticator_options) do
        {
          secure_token_uuid: secure_token.uuid,
          target_class: secure_token.target_type,
          target_id: secure_token.target_id,
          secret_key: secure_token.random_secret_key # this is important
        }
      end

      let!(:secure_token) { create(:secure_token) }

      it "returns the first secure token matching this pair" do
        expect(result).to eq(secure_token)
      end

      it "caches the secure token" do
        result
        expect(SecureToken).not_to receive(:where)
        result
      end

      it "sets the secure token to @secure_token" do
        result
        expect(subject.instance_variable_get(:@secure_token))
          .to eq(secure_token)
      end
    end

    context "no secure tokens exist for the uuid and target class" do
      let(:authenticator_options) do
        {
          secure_token_uuid: "doesnt-exist",
          target_class: "NotAClass",
          target_id: nil,
          secret_key: "probably-won't-work"
        }
      end

      let!(:secure_token) { create(:secure_token) }

      it "doesn't find anything and returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "checking uuid and secure key formatting" do
    # use this so sleep calls don't delay rspec
    let(:slowdown_duration) { 1e-10 }

    before do
      allow(subject).to receive(:slowdown_duration) { slowdown_duration }
    end

    describe "#uuid_format_valid?" do
      let(:result) { subject.uuid_format_valid? }

      before do
        allow(SecureTokenValidator::Regex).to receive(:uuid) { /VALID-UUID/ }
      end

      context "secure_token_uuid format matches the regex" do
        it "returns true" do
          allow(subject).to receive(:secure_token_uuid) { "VALID-UUID" }
          expect(result).to be_truthy
        end
      end

      context "secure_token_uuid format does not match the regex" do
        it "returns false" do
          allow(subject).to receive(:secure_token_uuid) { "invalid-uuid" }
          expect(result).to be_falsey
        end

        it "sleeps" do
          expect(subject).to receive(:sleep).with slowdown_duration
          result
        end
      end
    end

    describe "#secure_key_format_valid?" do
      let(:result) { subject.secure_key_format_valid? }

      before do
        allow(SecureTokenValidator::Regex).to receive(:secret_key)
          .and_return /VALID-SECRET-KEY/
      end

      before do
        allow(subject).to receive(:sleep) { 0.000000001 } # don't sleep for long
      end

      context "secure_key format matches the regex" do
        it "returns true" do
          allow(subject).to receive(:secret_key) { "VALID-SECRET-KEY" }
          expect(result).to be_truthy
        end
      end

      context "secure_key format does not match the regex" do
        it "returns false" do
          allow(subject).to receive(:secret_key) { "invalid-secret-key" }
          expect(result).to be_falsey
        end

        it "sleeps" do
          expect(subject).to receive(:sleep).with slowdown_duration
          result
        end
      end
    end
  end
end
