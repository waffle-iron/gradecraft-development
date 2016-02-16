require "active_record_spec_helper"
require_relative '../toolkits/models/shared/files'

describe AssignmentFile do
  let(:assignment) { build(:assignment) }

  subject { new_assignment_file }
  let(:new_assignment_file) { assignment.assignment_files.new image_file_attrs }

  extend Toolkits::Models::Shared::Files
  define_context # pull in attrs for image and text files


  describe "validations" do
    it "requires a filename" do
      subject.filename = nil
      expect(subject).to_not be_valid
      expect(subject.errors[:filename]).to include "can't be blank"
    end
  end

  describe "as a dependency of the submission" do
    it "is saved when the parent submission is saved" do
      subject.assignment.save!
      expect(subject.assignment_id).to equal assignment.id
      expect(subject.new_record?).to be_falsey
    end

    it "is deleted when the parent submission is destroyed" do
      subject.assignment.save!
      expect { assignment.destroy }.to change(AssignmentFile, :count).by(-1)
    end
  end

  describe "formatting name of mounted file" do
    subject { new_assignment_file.read_attribute(:file) }
    let(:save_assignment) { new_assignment_file.assignment.save! }

    it "accepts text files as well as images" do
      new_assignment_file.file = fixture_file('test_file.txt', 'txt')
      save_assignment
      expect expect(subject).to match(/\d+_test_file\.txt/)
    end

    it "has an accessible url" do
      save_assignment
      expect expect(subject).to match(/\d+_test_image\.jpg/)
    end

    it "shortens and removes non-word characters from file names on save" do
      new_assignment_file.file = fixture_file('Too long, strange characters, and Spaces (In) Name.jpg', 'img/jpg')
      save_assignment
      expect(subject).to match(/\d+_too_long__strange_characters__and_spaces_\.jpg/)
    end
  end

  describe "#copy", focus: true do
    let(:assignment_file) { build :assignment_file, filename: "test_file.txt", file: fixture_file("test_file.txt", "txt") }
    subject { assignment_file.copy }

    it "prepends the filename with 'copy_of'" do
      assignment_file.save
      expect(subject.filename).to eq "copy_of_test_file.txt"
    end
  end

  describe "url" do
    subject { new_assignment_file.url }
    before { allow(new_assignment_file).to receive_message_chain(:s3_object, :presigned_url) { "http://some.url" }}

    it "returns the presigned amazon url" do
      expect(subject).to eq("http://some.url")
    end
  end

  describe "#course" do
    it "returns the associated course" do
      course = create(:course)
      assignment.course = course
      expect(subject.course).to eq(course)
    end
  end

  describe "S3Manager::Carrierwave inclusion" do
    let(:assignment_file) { build(:assignment_file) }

    it "can be deleted from s3" do
      expect(assignment_file.respond_to?(:delete_from_s3)).to be_truthy
    end

    it "can check whether it exists on s3" do
      expect(assignment_file.respond_to?(:exists_on_s3?)).to be_truthy
    end
  end
end
