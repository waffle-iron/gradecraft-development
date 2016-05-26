require "action_view"
require "active_record_spec_helper"
require_relative "../support/test_classes/validators/file_size_validator_test"

describe FileSizeValidator do

  # load a test class from /spec/support/test_classes
  describe FileSizeValidatorTest do
    let(:image) { fixture_file "test_image.jpg", "img/jpg" }
    let(:uploader) { ImageUploader.new subject, :media }
    subject { described_class.new }

    before do
      I18n.load_path << "./config/locales/en.yml"
      subject.class.clear_validators!
      uploader.store! image
    end

    it "is valid if the size is within range" do
      subject.class.validates :media, file_size: { maximum: 4.megabytes.to_i }
      subject.media = uploader
      expect(subject).to be_valid
    end

    it "must be an uploader" do
      subject.class.validates :media, file_size: true
      subject.media = image
      expect { subject.valid? }.to raise_error ArgumentError
    end

    it "is invalid if the file size exceeds the maximum size" do
      subject.class.validates :media, file_size: { maximum: 2.kilobytes.to_i }
      subject.media = uploader
      expect(subject).to_not be_valid
      expect(subject.errors[:media]).to include "is too big (should be at most 2 KB)"
    end

    it "is invalid if the file size falls below the minimum size" do
      subject.class.validates :media, file_size: { minimum: 4.megabytes.to_i }
      subject.media = uploader
      expect(subject).to_not be_valid
      expect(subject.errors[:media]).to include "is too small (should be at least 4 MB)"
    end

    it "is invalid if the file size is not within a range" do
      subject.class.validates :media, file_size: { in: 4.megabytes.to_i..6.megabytes.to_i }
      subject.media = uploader
      expect(subject).to_not be_valid
      expect(subject.errors[:media]).to include "is too small (should be at least 4 MB)"
    end

    it "is invalid of the file size does not equal a specific size" do
      subject.class.validates :media, file_size: { is: 4.megabytes.to_i }
      subject.media = uploader
      expect(subject).to_not be_valid
      expect(subject.errors[:media]).to include "is the wrong size (should be 4 MB)"
    end
  end
end
