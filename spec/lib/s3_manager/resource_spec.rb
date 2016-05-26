require_relative "../../../lib/s3_manager/resource"
require_relative "../../support/test_classes/lib/s3_manager/s3_resource_test"

RSpec.describe S3Manager::Resource do
  subject { S3ResourceTest.new s3_object_key: s3_object_key }

  let(:s3_manager) { double(S3Manager::Manager).as_null_object }
  let(:s3_object_key) { "some-fake-key" }
  let(:temp_file) { Tempfile.new("some-file") }

  describe "#s3_manager" do
    let(:result) { subject.s3_manager }

    it "builds a new S3Manager::Manager object" do
      expect(S3Manager::Manager).to receive(:new)
      result
    end

    it "caches the object" do
      result
      expect(S3Manager::Manager).not_to receive(:new)
      result
    end

    it "sets the S3Manager object to @s3_manager" do
      allow(S3Manager::Manager).to receive(:new) { s3_manager }
      expect(result).to eq s3_manager
    end
  end

  describe "behaviors that don't define s3_manager" do
    before do
      allow(subject).to receive(:s3_manager) { s3_manager }
    end

    describe "#upload_file_to_s3" do
      it "puts the encrypted object to s3" do
        expect(s3_manager).to receive(:put_encrypted_object)
          .with(s3_object_key, temp_file)
        subject.upload_file_to_s3(temp_file)
      end
    end

    describe "#fetch_object_from_s3" do
      it "fetches the encrypted object from s3" do
        expect(s3_manager).to receive(:get_encrypted_object)
          .with(s3_object_key)
        subject.fetch_object_from_s3
      end
    end

    describe "#stream_s3_object_body" do
      let(:result) { subject.stream_s3_object_body }
      it "fetches the encrypted object from s3" do
        expect(s3_manager).to receive(:get_encrypted_object).with(s3_object_key)
        result
      end

      context "s3_object doesn't exist" do
        it "returns nil" do
          allow(subject).to receive(:fetch_object_from_s3) { nil }
          expect(result).to be_nil
        end
      end

      context "s3_object exists" do
        let(:s3_object) { double(:s3_object).as_null_object }

        before do
          allow(subject).to receive(:fetch_object_from_s3) { s3_object }
        end

        context "s3_object has no body" do
          it "returns nil" do
            allow(s3_object).to receive(:body) { nil }
            expect(result).to be_nil
          end
        end

        context "s3_object has a body" do
          it "streams the object body via #read" do
            allow(s3_object).to receive_message_chain(:body, :read) { "a-body" }
            expect(result).to eq("a-body")
          end
        end
      end
    end

    describe "#write_s3_object_to_file" do
      it "writes the encrypted object to a local file" do
        expect(s3_manager).to receive(:write_encrypted_object_to_file)
          .with(s3_object_key, temp_file)
        subject.write_s3_object_to_file(temp_file)
      end
    end

    describe "#delete_object_from_s3" do
      it "deletees the encrypted object from s3" do
        expect(s3_manager).to receive(:delete_object).with(s3_object_key)
        subject.delete_object_from_s3
      end
    end

    describe "#s3_object_exists?" do
      it "checks whether the s3_object_exists?" do
        expect(subject).to receive_message_chain(:s3_object_summary, :exists?)
        subject.s3_object_exists?
      end
    end

    describe "#s3_object_summary" do
      let(:result) { subject.s3_object_summary }

      it "builds a new object summary with the object key and the s3 manager" do
        expect(S3Manager::Manager::ObjectSummary).to receive(:new)
          .with(s3_object_key, s3_manager)
        result
      end

      it "returns an ObjectSummary object" do
        expect(result.class).to eq(S3Manager::Manager::ObjectSummary)
      end

      it "caches the new object summary" do
        result
        expect(S3Manager::Manager::ObjectSummary).not_to receive(:new)
        result
      end
    end

    describe "#presigned_s3_url" do
      it "gets the presigned url for the s3 object" do
        expect(subject.s3_manager).to receive_message_chain(
          :bucket, :object, :presigned_url, :to_s)
        subject.presigned_s3_url
      end
    end
  end
end
