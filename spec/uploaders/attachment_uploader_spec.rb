require "active_record_spec_helper"
require_relative "../toolkits/uploaders/attachment_uploader"
require_relative "../support/uni_mock/rails"
require_relative "../support/uni_mock/stub_time"
require_relative "../support/random_file/content"

include Toolkits::Uploaders::AttachmentUploader

RSpec.describe AttachmentUploader do
  subject { AttachmentUploader.new(model, :file) }
  include UniMock::StubTime
  include UniMock::StubRails

  let(:model) { MockClass::FullUpFileKlass.new }

  describe "#store_dir" do
    it "joins the store_dir_pieces" do
      allow(subject).to receive(:store_dir_pieces) { ["some","dir","items"] }
      expect(subject.store_dir).to eq "some/dir/items"
    end
  end

  describe "#filename" do
    let(:result) { subject.filename }

    let(:stub_tokenized_name_with_extension) do
      allow(subject).to receive_messages(
        tokenized_name: "sweet_name",
        file: double(:file, extension: "txt")
      )
    end

    context "original filename is present" do
      before(:each) { allow(subject).to receive(:original_filename) { "cool_filename_bro.txt" }}
      let(:model) { MockClass::MountedClass.new }

      context "model exists and has a mounted_as attribute" do
        it "reads the mounted_as attribute from the model" do
          expect(result).to eq("mountable_something.pdf")
        end
      end

      context "model doesn't exist" do
        let(:model) { nil }
        before { stub_tokenized_name_with_extension }

        it "uses the tokenized name with the extension of the associated file" do
          expect(result).to eq("sweet_name.txt")
        end
      end

      context "model doesn't have an attribute for #mounted_as" do
        let(:model) { MockClass::MountedClassWithoutAttribute.new }
        before { stub_tokenized_name_with_extension }

        it "uses the tokenized name with the extension of the associated file" do
          expect(result).to eq("sweet_name.txt")
        end
      end
    end

    context "original filename is not present" do
      before { allow(subject).to receive(:original_filename) { nil }}
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#store_dir_pieces" do
    let(:result) { subject.store_dir_pieces }

    before(:each) do
      allow(subject).to receive_messages(
        store_dir_prefix: "some-prefix",
        course: "some-course",
        assignment: "some-assignment",
        file_klass: "devious_files",
        owner_name: "dave-eversby"
      )
    end

    it "returns an array with those components" do
      expect(result).to eq(
        [
          "some-prefix", "uploads", "some-course", "some-assignment",
          "devious_files", "dave-eversby"
        ]
      )
    end

    it "compacts nils from the array" do
      allow(subject).to receive_messages(course: nil, file_klass: nil)
      expect(result).to eq([ "some-prefix", "uploads", "some-assignment", "dave-eversby" ])
    end
  end

  describe "#course" do
    let(:result) { subject.course }
    let(:course) { create(:course) }

    context "model has a course method" do
      it "returns a string with the format of <courseno-course_id>" do
        allow(model).to receive(:course) { course }
        expect(result).to eq("#{course.courseno}-#{course.id}")
      end
    end

    context "model has no course method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#assignment" do
    let(:result) { subject.assignment }
    let(:assignment) { create(:assignment) }

    context "model has an assignment method" do
      it "returns a string with the format of <assignment_name-assignment_id>" do
        allow(model).to receive(:assignment) { assignment }
        expect(result).to eq("assignments/#{model.assignment.name.gsub(/\s/, "_").downcase[0..20]}-#{model.assignment.id}")
      end
    end

    context "model has no assignment method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#file_klass" do
    let(:result) { subject.file_klass }

    it "formats the name of the file class" do
      expect(result.split("/").last).to eq "full_up_file_klasses"
    end
  end

  describe "#owner_name" do
    let(:result) { subject.owner_name }

    context "model has an owner_name method" do
      it "returns a string with the format of <owner_name_name-owner_name_id>" do
        allow(model).to receive(:owner_name) { " herman   jeffberry " }
        expect(result).to eq " herman   jeffberry "
      end
    end

    context "model has no owner_name method" do
      let(:model) { MockClass::EmptyFileKlass.new }
      it "returns nil" do
        expect(result).to be_nil
      end
    end
  end

  describe "#tokenized_name" do
    let(:result) { subject.tokenized_name }
    let(:secure_token_name) { RandomFile::Content.random_string(20) }
    let(:secure_token_value) { RandomFile::Content.random_string(30) }
    let(:random_filename) { RandomFile::Content.random_string(40) }

    before(:each) do
      allow(subject).to receive_messages({
        secure_token_name: :"@#{secure_token_name}",
        filename_from_basename: random_filename
      })
    end

    context "model has an instance variable with the secure_token_name" do
      it "returns the value of the instance variable" do
        model.instance_variable_set(:"@#{secure_token_name}", secure_token_value)
        expect(result).to eq(secure_token_value)
      end
    end

    context "model @secure_token_name is nil" do
      before { model.instance_variable_set(:"@#{secure_token_name}", nil) }

      it "sets the secure token name as the filename_from_basename" do
        result
        expect(model.instance_variable_get(:"@#{secure_token_name}")).to eq random_filename
      end

      it "returns the filename_from_basename" do
        expect(result).to eq random_filename
      end
    end
  end

  describe "#filename_from_basename" do
    let(:result) { subject.filename_from_basename }
    let(:file_basename) { "walter    was    acting%%$  #@ strange today%%%" }

    before do
      stub_now("Oct 20 1999")
      allow(subject).to receive(:file) { double(:file, basename: file_basename) }
    end

    it "uses the time in microseconds and formats the basename" do
      expect(result).to eq "#{Time.now.to_i}_walter_was_acting_strange_today_"
    end
  end

  describe "#secure_token_name" do
    let(:result) { subject.secure_token_name }
    let(:subject) { AttachmentUploader.new(model, :berry_pancakes) }

    it "pulls the mounted_at value from the AttachmentUploader" do
      expect(result).to eq :"@berry_pancakes_secure_token"
    end

    it "expects/uses a token named based on the #mounted_as value" do
      allow(subject).to receive(:mounted_as) { "stuff_srsly" }
      expect(result).to eq :"@stuff_srsly_secure_token"
    end
  end

  after(:all) do
    FileUtils.rm_rf(Dir["#{Rails.root}/uploads"])
  end
end
