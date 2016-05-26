require "active_model"
require_relative "../../../app/validators/secure_token_validator/regex"

describe SecureTokenValidator::Regex do
  describe ".uuid" do
    it "matches standard UUIDs" do
      expect(described_class.uuid).to match SecureRandom.uuid
    end
  end

  describe ".secret_key" do
    it "matches strings of 254-character 190-bit secret keys" do
      expect(described_class.secret_key)
        .to match SecureRandom.urlsafe_base64(190)
    end
  end

  describe ".encrypted_key" do
    let(:result) { described_class.encrypted_key }
    let(:hex_key) { SecureRandom.hex 525 } # 1050-character hex key

    it "matches 1050 character hex keys" do
      expect(result).to match hex_key
    end

    it "matches 1049 character hex keys" do
      expect(result).to match hex_key[0..1048]
    end
  end
end
