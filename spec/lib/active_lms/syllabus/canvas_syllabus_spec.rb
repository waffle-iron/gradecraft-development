require "api_spec_helper"
require "./lib/active_lms"

describe ActiveLMS::CanvasSyllabus, type: :disable_external_api do
  let(:access_token) { "BLAH" }

  before do
    allow(Canvas::API).to \
      receive(:base_uri).and_return "https://canvas.instructure.com/api/v1"
  end

  describe "#initialize" do
    it "initializes a new canvas API wrapper" do
      expect(Canvas::API).to \
        receive(:new).with(access_token).and_call_original
      described_class.new access_token
    end
  end

  describe "#assignment" do
    let(:stub) do
      stub_request(:get,
                   "https://canvas.instructure.com/api/v1/courses/123/assignments/456")
        .with(query: { "access_token" => access_token })
    end
    subject { described_class.new access_token }

    context "with a successful API call" do
      it "retrieves the assignment for the id from the api" do
        body = { name: "This is a published assignment" }
        stub.to_return(status: 200, body: body.to_json, headers: {})

        assignment = subject.assignment(123, 456)

        expect(assignment["name"]).to eq "This is a published assignment"
      end
    end

    context "with an API error" do
      let!(:json_error) { stub.to_raise(JSON::ParserError) }

      it "calls the exception handler if one is provided" do
        expect { |b| subject.assignment(123, 456, &b) }.to \
          yield_with_args(instance_of(JSON::ParserError))
      end

      it "raises the error if an exception handler is not provided" do
        expect { subject.assignment(123, 456) }.to raise_error JSON::ParserError
      end
    end
  end

  describe "#assignments" do
    let(:stub) do
      stub_request(:get, "https://canvas.instructure.com/api/v1/courses/123/assignments")
        .with(query: { "access_token" => access_token })
    end
    subject { described_class.new access_token }

    context "with a successful API call" do
      it "retrieves the published assignments for the course from the api" do
        body = [{ name: "This is a published assignment", published: true },
                { name: "This is an unpublished assignment", published: false }]
        stub.to_return(status: 200, body: body.to_json, headers: {})

        assignments = subject.assignments(123)

        expect(assignments.count).to eq 1
        expect(assignments.first["name"]).to eq "This is a published assignment"
      end

      context "for specific ids" do
        let!(:stub) do
          stub_request(:get,
                       "https://canvas.instructure.com/api/v1/courses/123/assignments/456")
            .with(query: { "access_token" => access_token })
            .to_return(status: 200, body: { name: "This is an assignment" }.to_json,
                       headers: {})
        end

        it "retrieves the assignment details from the api" do
          subject.assignments(123, 456)

          expect(stub).to have_been_requested
        end

        it "handles multiple assignment ids" do
          stub2 = stub_request(:get,
            "https://canvas.instructure.com/api/v1/courses/123/assignments/789")
            .with(query: { "access_token" => access_token })
            .to_return(status: 200, body: { name: "This is an assignment" }.to_json,
                       headers: {})

          subject.assignments(123, [456, 789])

          expect(stub2).to have_been_requested
        end

        it "does not call the api for double assignment ids" do
          subject.assignments(123, [456, 456])

          expect(stub).to have_been_requested.once
        end

        it "does not call the api for nil assignment ids" do
          stub.request_pattern = WebMock::RequestPattern.new(:get,
            "https://canvas.instructure.com/api/v1/courses/123/assignments/")
              .with(query: { "access_token" => access_token })
          subject.assignments(123, [nil])

          expect(stub).to_not have_been_requested
        end
      end
    end

    context "with an API error" do
      let!(:json_error) { stub.to_raise(JSON::ParserError) }

      it "calls the exception handler if one is provided" do
        expect { |b| subject.assignments(123, &b) }.to \
          yield_with_args(instance_of(JSON::ParserError))
      end

      it "raises the error if an exception handler is not provided" do
        expect { subject.assignments(123) }.to raise_error JSON::ParserError
      end
    end
  end

  describe "#course" do
    let(:stub) do
      stub_request(:get, "https://canvas.instructure.com/api/v1/courses/123")
        .with(query: { "access_token" => access_token })
    end
    subject { described_class.new access_token }

    context "with a successful API call" do
      it "retrieves the course for the id from the api" do
        stub.to_return(status: 200, body: { name: "This is a course" }.to_json, headers: {})

        course = subject.course(123)

        expect(course).to_not be_nil
        expect(course["name"]).to eq "This is a course"
      end
    end

    context "with an API error" do
      let!(:json_error) { stub.to_raise(JSON::ParserError) }

      it "calls the exception handler if one is provided" do
        expect { |b| subject.course(123, &b) }.to \
          yield_with_args(instance_of(JSON::ParserError))
      end

      it "raises the error if an exception handler is not provided" do
        expect { subject.course(123) }.to raise_error JSON::ParserError
      end
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

  describe "#grades" do
    let(:assignment_ids) { [456, 789] }
    let(:stub) do
      stub_request(:get,
          "https://canvas.instructure.com/api/v1/courses/123/students/submissions")
        .with(query: { "assignment_ids" => assignment_ids, "student_ids" => "all",
                       "include" => ["assignment", "course", "user"],
                       "access_token" => access_token })
    end
    subject { described_class.new access_token }

    context "with a successful API call" do
      let!(:successful_stub) do
        stub.to_return(status: 200, body: [{ id: 456, score: 87 }].to_json, headers: {})
      end

      it "retrieves the grades from the api" do
        grades = subject.grades(123, assignment_ids)

        expect(grades.count).to eq 1
        expect(grades.first["score"]).to eq 87
      end

      context "for specific ids" do
        it "filters out a single id" do
          grades = subject.grades(123, assignment_ids, "456")

          expect(grades.first["id"]).to eq 456
        end

        it "does not duplicate the grades for double grade ids" do
          grades = subject.grades(123, assignment_ids, [456, 456])

          expect(grades.count).to eq 1
        end

        it "filters out the grade ids" do
          grades = subject.grades(123, assignment_ids, [123])

          expect(grades).to be_empty
        end
      end
    end

    context "with an API error" do
      let!(:json_error) { stub.to_raise(JSON::ParserError) }

      it "calls the exception handler if one is provided" do
        expect { |b| subject.grades(123, assignment_ids, "456",  &b) }.to \
          yield_with_args(instance_of(JSON::ParserError))
      end

      it "raises the error if an exception handler is not provided" do
        expect { subject.grades(123, assignment_ids, "456") }.to raise_error JSON::ParserError
      end
    end
  end

  describe "#update_assignment" do
    subject { described_class.new access_token }

    it "updates the assignment for the id from the api" do
      request = { assignment: { name: "This is a published assignment" }}
      body = { id: "123", name: "This is a published assignment" }
      stub_request(:put,
                   "https://canvas.instructure.com/api/v1/courses/123/assignments/456")
        .with(query: { "access_token" => access_token }, body: request.to_json)
        .to_return(status: 200, body: body.to_json,
                   headers: {})

      assignment = subject.update_assignment(123, 456, request)

      expect(assignment["name"]).to eq "This is a published assignment"
    end
  end

  describe "#user" do
    subject { described_class.new access_token }

    it "retrieves the user for the id from the api" do
      stub_request(:get, "https://canvas.instructure.com/api/v1/users/123/profile")
        .with(query: { "access_token" => access_token })
        .to_return(status: 200, body: { name: "Jimmy Page" }.to_json,
                   headers: {})

      user = subject.user(123)

      expect(user).to_not be_nil
      expect(user["name"]).to eq "Jimmy Page"
    end
  end
end
