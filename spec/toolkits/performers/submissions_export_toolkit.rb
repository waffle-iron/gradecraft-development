module Toolkits
  module Performers
    module SubmissionsExport

      module Context
        def define_context
          # public methods
          let(:course) { create(:course) }
          let(:professor_course_membership) { create(:professor_course_membership, course: course) }
          let(:professor) { professor_course_membership.user }
          let(:assignment) { create(:assignment, course: course) }
          let(:team) { create(:team) }
          let(:student_course_membership1) { create(:student_course_membership, course: course) }
          let(:student_course_membership2) { create(:student_course_membership, course: course) }
          let(:team_membership1) { create(:team_membership, student: student1, team: team) }
          let(:team_membership2) { create(:team_membership, student: student2, team: team) }
          let(:cache_team_memberships) { team_membership1; team_membership2 }
          let(:students) { [ student_course_membership1.user, student_course_membership2.user ] }
          let(:student1) { student_course_membership1.user }
          let(:student2) { student_course_membership2.user }
          let(:submission1) { create(:submission, assignment: assignment, student: student_course_membership1.user) }
          let(:submission2) { create(:submission, assignment: assignment, student: student_course_membership2.user) }
          let(:submissions) { [ submission1, submission2 ] }
          let(:submissions_export) do
            create(:submissions_export, course: course, professor: professor, assignment: assignment, team: team)
          end

          let(:job_attrs) {{ professor_id: professor.id, assignment_id: assignment.id,
                             submissions_export_id: submissions_export.id }}
          let(:job_attrs_with_team) { job_attrs.merge(team_id: team.try(:id)) }

          let(:performer) { SubmissionsExportPerformer.new(job_attrs) }
          let(:performer_with_team) { SubmissionsExportPerformer.new(job_attrs_with_team) }
        end
      end

      module SharedExamples
        RSpec.shared_examples "an expandable messages hash" do
          it "expands the base messages" do
            expect(performer).to receive(:expand_messages)
            subject
          end
        end

        RSpec.shared_examples "it has a success message" do |message|
          it "has a success message" do
            expect(subject[:success]).to match(message)
          end
        end

        RSpec.shared_examples "it has a failure message" do |message|
          it "has a failure message" do
            expect(subject[:failure]).to match(message)
          end
        end

        RSpec.shared_examples "a created student directory" do |dir_path|
          it "actually creates the directory on disk" do
            subject
            expect(File.exist?(dir_path)).to be_truthy
          end

          it "makes a directory for the student path" do
            expect(Dir).to receive(:mkdir).with(dir_path)
            subject
          end
        end
      end

    end
  end
end
