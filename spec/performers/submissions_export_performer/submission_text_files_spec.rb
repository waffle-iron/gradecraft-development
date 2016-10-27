require "rails_spec_helper"
require "active_record_spec_helper"

RSpec.describe SubmissionsExportPerformer, type: :background_job do
  include PerformerToolkit::SharedExamples
  include Toolkits::Performers::SubmissionsExport::SharedExamples
  extend Toolkits::Performers::SubmissionsExport::Context
  define_context

  subject { performer }

  describe "creating student submission text files", inspect: true do
    let(:student1) { create(:user, first_name: "edwina", last_name: "herman") }
    let(:student2) { create(:user, first_name: "karen", last_name: "slotskova") }
    let(:submission1) { create(:submission, text_comment: "This was tough.", link: "http://greatjob.com", student: student1) }
    let(:mkdir) { FileUtils.mkdir_p("/tmp/great_files") unless Dir.exist?("/tmp/great_files") }
    let(:text_file) { File.readlines(text_file_path) }
    let(:delete_text_file) { File.delete(text_file_path) if File.exist?(text_file_path) }

    before { mkdir }
    before(:each) { performer.instance_variable_set(:@some_student, student1) }

    describe "create_submission_text_files", inspect: true do
      subject { performer.instance_eval { create_submission_text_files }}
      before(:each) { performer.instance_variable_set(:@submissions, [ submission1 ]) }

      context "submission has a text comment or a link" do
        it "creates a text file for the submission" do
          expect(performer).to receive(:create_submission_text_file).with (submission1)
          subject
        end
      end

      context "submission has neither a comment nor a link" do
        let(:submission1) { create(:submission_with_files_only, text_comment: nil, link: nil) }

        it "doesn't create a text file for the submission" do
          expect(performer).not_to receive(:create_submission_text_file).with (submission1)
          subject
        end
      end
    end

    describe "create_submission_text_file", inspect: true do
      subject { performer.instance_eval { create_submission_text_file(@some_submission) }}
      let(:text_file_path) { "/tmp/great_files/submission_path.txt" }

      before(:each) do
        performer.instance_variable_set(:@some_submission, submission1)
        allow(performer).to receive(:submission_text_file_path) { text_file_path }
      end

      it "creates a file at the text file path" do
        expect(performer).to receive(:open).with(text_file_path, "w")
        subject
      end

      it "creates a title line with the student name" do
        subject
        expect(text_file.first).to eq("Submission items from herman, edwina\n")
      end

      describe "conditional text file elements" do
        before(:each) { subject } # the file will be overwritten each time
        after(:each) { delete_text_file }

        describe "submission text comment" do

          context "submission has a text comment" do
            it "adds the text comment to the text file" do
              expect(text_file[2]).to eq("text comment: This was tough.\n")
            end

            it "creates a complete file" do
              expect(text_file.size).to eq(5)
            end
          end

          context "submission doesn't have a text comment" do
            let(:submission1) { create(:submission, text_comment: nil, link: "http://greatjob.com", student: student1) }

            it "doesn't add the text comment to the text file" do
              expect(text_file).not_to include("text comment: This was tough.\n")
            end

            it "builds a file with two fewer lines" do
              expect(text_file.size).to eq(3)
            end
          end
        end

        describe "submission link" do
          context "submission has a link" do
            it "adds the link to the text file" do
              expect(text_file.last).to eq("link: http://greatjob.com\n")
            end

            it "creates a complete file" do
              expect(text_file.size).to eq(5)
            end
          end

          context "submission doesn't have a link" do
            let(:submission1) { create(:submission, text_comment: "This was tough.", link: nil, student: student1) }

            it "doesn't add link the text file" do
              expect(text_file).not_to include("link: http://greatjob.com\n")
            end

            it "builds a file with two fewer lines" do
              expect(text_file.size).to eq(3)
            end
          end
        end

      end
    end

    describe "submission_text_file_path", inspect: true do
      subject { performer.instance_eval { submission_text_file_path(@some_student) }}

      before do
        allow(performer).to receive(:submission_text_filename) { "garrett_hornsby.txt" }
        allow(performer).to receive(:submitter_directory_path) { "/some/student/dir" }
      end

      it "builds the correct file path" do
        expect(subject).to eq("/some/student/dir/garrett_hornsby.txt")
      end
    end

    describe "submission_text_filename", inspect: true do
      before do
        allow(performer.submissions_export)
          .to receive(:formatted_assignment_name)
          .and_return "the_day_the_earth_stood_still"
      end

      subject { performer.instance_eval { submission_text_filename(@some_student) }}

      it "builds the filename" do
        expect(subject).to eq("Edwina Herman - the_day_the_earth_stood_still - Submission Text.txt")
      end

      it "uses the formatted_assignment_name" do
        expect(performer.submissions_export).to receive(:formatted_assignment_name)
        subject
      end

      it "uses the formatted_submitter_name" do
        expect(performer).to receive(:formatted_submitter_name).with(student1)
        subject
      end

      it "includes the student name" do
        expect(subject).to include("Edwina")
      end

      it "includes the filename" do
        expect(subject).to include("Herman")
      end

      it "includes the default_suffix" do
        expect(subject).to include("Submission Text.txt")
      end
    end
  end

end
