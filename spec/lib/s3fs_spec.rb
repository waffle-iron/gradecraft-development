require "s3fs"

describe S3fs do
  describe ".mktmpdir" do
    it "makes a tmpdir using the tmpdir_prefix" do
      allow(S3fs).to receive(:tmpdir_prefix) { nil }
      expect(Dir).to receive(:mktmpdir).with(nil, nil)
      S3fs.mktmpdir
    end
  end

  describe ".available?" do
    context "rails_env is staging or production" do
      it "tells us that s3fs is available" do
        allow(S3fs).to receive(:rails_env) { "staging" }
        expect(S3fs.available?).to eq true

        allow(S3fs).to receive(:rails_env) { "production" }
        expect(S3fs.available?).to eq true
      end
    end

    context "rails_env is anything else" do
      it "tells us that s3fs is not available" do
        allow(S3fs).to receive(:rails_env) { "development" }
        expect(S3fs.available?).to eq false

        allow(S3fs).to receive(:rails_env) { "test" }
        expect(S3fs.available?).to eq false
      end
    end
  end

  describe ".tmpdir_prefix" do
    context "s3fs is available" do
      it "uses the s3mnt env-specific prefix" do
        allow(S3fs).to receive_messages \
          available?: true,
          rails_env: "staging"

        expect(S3fs.tmpdir_prefix).to eq "/s3mnt/tmp/staging"
      end
    end

    context "s3fs is not available" do
      it "returns nil, which uses the system-default prefix" do
        allow(S3fs).to receive(:available?) { false }
        expect(S3fs.tmpdir_prefix).to be_nil
      end
    end
  end

  describe ".ensure_tmpdir" do
    it "makes the tmpdir if s3fs is available" do
      allow(S3fs).to receive_messages \
        available?: true,
        rails_env: "staging"

      expect(FileUtils).to receive(:mkdir_p).with("/s3mnt/tmp/staging")
      S3fs.ensure_tmpdir
    end
  end

  describe ".rails_env" do
    it "returns the value of ENV['RAILS_ENV']" do
      expect(S3fs.rails_env).to eq "test"
    end
  end
end
