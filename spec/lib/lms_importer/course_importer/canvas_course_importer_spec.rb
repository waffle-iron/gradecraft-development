require "api_spec_helper"
require "./lib/lms_importer"

describe LMSImporter::CanvasCourseImporter, type: :disable_external_api do
  let(:access_token) { "BLAH" }

  describe "#initialize" do
    it "initializes a new canvas API wrapper" do
      expect(Canvas::API).to \
        receive(:new).with(access_token).and_call_original
      described_class.new access_token
    end
  end

  describe "#assignments" do
    subject { described_class.new access_token }

    it "retrieves the assignments for the course from the api" do
      stub_request(:get, "https://canvas.instructure.com/api/v1/courses/123/assignments")
        .with(query: { "access_token" => access_token })
        .to_return(status: 200, body: [{ name: "This is an assignment" }].to_json,
                   headers: {})

      assignments = subject.assignments(123)

      expect(assignments.count).to eq 1
      expect(assignments.first["name"]).to eq "This is an assignment"
    end
  end

  describe "#course" do
    subject { described_class.new access_token }

    it "retrieves the course for the id from the api" do
      stub_request(:get, "https://canvas.instructure.com/api/v1/courses/123")
        .with(query: { "access_token" => access_token })
        .to_return(status: 200, body: { name: "This is a course" }.to_json,
                   headers: {})

      course = subject.course(123)

      expect(course).to_not be_nil
      expect(course["name"]).to eq "This is a course"
    end
  end

  describe "#courses" do
    subject { described_class.new access_token }

    it "retrieves the courses from the api" do
      stub_request(:get, "https://canvas.instructure.com/api/v1/courses")
        .with(query: { "enrollment_type" => "teacher", "access_token" => access_token })
        .to_return(status: 200, body: [{ name: "This is a course" }].to_json, headers: {})

      courses = subject.courses

      expect(courses.count).to eq 1
      expect(courses.first["name"]).to eq "This is a course"
    end
  end

  describe "#import_assignments" do
    let(:course) { double(:course) }
    subject { described_class.new access_token }

    it "retrieves the assignment details from the api" do
      stub = stub_request(:get,
        "https://canvas.instructure.com/api/v1/courses/123/assignments/456")
        .with(query: { "access_token" => access_token })
        .to_return(status: 200, body: [{ name: "This is an assignment" }].to_json,
                   headers: {})

      subject.import_assignments(123, 456, course)

      expect(stub).to have_been_requested
    end

    xit "handles multiple assignment ids"
    xit "does not process double assignment ids"
  end
end
