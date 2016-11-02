require "rails_spec_helper"

RSpec.describe "Assignment #missing_binaries methods" do
  let(:missing_submission_file) { create(:missing_submission_file, submission: submission_with_missing_file) }
  let(:submission_with_missing_file) { create(:submission, assignment: assignment, student: student1) }
  let(:student1) { create(:user) }

  let(:present_submission_file) { create(:present_submission_file, submission: submission_with_present_file) }
  let(:submission_with_present_file) { create(:submission, assignment: assignment, student: student2) }
  let(:student2) { create(:user) }

  let(:another_missing_submission_file) { create(:missing_submission_file, submission: another_submission_with_missing_file) }
  let(:another_submission_with_missing_file) { create(:submission, assignment: assignment, student: student3) }
  let(:student3) { create(:user) }

  let(:assignment) { create(:assignment) }
  let(:cache_submission_files) { missing_submission_file; present_submission_file }

  before(:each) { cache_submission_files }

  context "no team is given" do
    describe "#submission_files_with_missing_binaries" do
      subject { assignment.submission_files_with_missing_binaries }

      context "submission file is marked 'file_missing'" do
        it "returns missing submission_files for the the assignment" do
          expect(subject).to include(missing_submission_file)
        end
      end

      context "submission file is not marked 'file_missing'" do
        it "doesn't return non-missing submission files" do
          expect(subject).not_to include(present_submission_file)
        end
      end

      describe "ordering" do
        let(:cache_submission_files) { missing_submission_file; present_submission_file; another_missing_submission_file }

        it "orders the submission files by create_at ASC" do
          expect(subject.to_a.index(missing_submission_file)).to \
            be < subject.to_a.index(another_missing_submission_file)
        end
      end

      describe "assignment association" do
        let(:cache_submission_files) { missing_submission_file; present_submission_file; another_missing_submission_file }
        let(:another_submission_with_missing_file) { create(:submission, student: student3) } # some other assignment

        context "submission file is associated with submission for that assignment" do
          it "returns the submission file" do
            expect(subject).to include(missing_submission_file)
          end
        end

        context "submission_file is associated with another assignment" do
          it "doesn't return the submission file" do
            expect(subject).not_to include(another_missing_submission_file)
          end
        end
      end
    end

    describe "#submitters_with_missing_binaries" do
      subject { assignment.submitters_with_missing_binaries }

      let(:cache_submission_files) do
        missing_submission_file
        present_submission_file
        another_missing_submission_file
      end

      it "returns submitters that have submissions for the assignment" do
        expect(subject).to include(student1)
      end

      it "doesn't return submitters that don't have a submission for the assignment" do
        expect(subject).not_to include(student2)
      end

      it "orders the students by name" do
        expect(subject.first.submitter_directory_name <
          subject.last.submitter_directory_name).to be_truthy
      end

      describe "assignment association" do
        let(:another_submission_with_missing_file) do
          # some other assignment
          create(:submission, student: student3)
        end

        context "user has submissions with missing files for the assignment" do
          it "returns the user with those files" do
            expect(subject).to include(student1)
          end
        end

        context "user has submissions with missing files that don't belong to the assignment" do
          it "doesn't return the user whose files belong to the third-party assignment" do
            expect(subject).not_to include(student3)
          end
        end
      end
    end
  end

  context "a team is given" do
    let(:team) { create(:team) }
    let(:team_membership) { create(:team_membership, team: team, student: student1) }
    let(:another_team_membership) { create(:team_membership, team: team, student: student3) }

    let(:cache_submission_files) { missing_submission_file; present_submission_file; another_missing_submission_file }
    let(:cache_team_memberships) { team_membership }

    before(:each) { cache_team_memberships }

    describe "#submission_files_with_missing_binaries_for_team" do
      subject { assignment.submission_files_with_missing_binaries_for_team(team) }

      context "submission file is marked 'file_missing'" do
        context "student who submitted the file is on the given team" do
          it "returns missing submission_files for the assignment for students on the given team" do
            expect(subject).to include(missing_submission_file)
          end
        end

        context "student who submitted the file is not on the team" do
          it "returns missing submission_files for the assignment for students on the given team" do
            expect(subject).not_to include(another_missing_submission_file)
          end
        end
      end

      context "submission file is not marked 'file_missing'" do
        it "doesn't return non-missing submission files" do
          expect(subject).not_to include(present_submission_file)
        end
      end

      describe "ordering" do
        let(:cache_team_memberships) { team_membership; another_team_membership }

        it "orders the submission files by create_at ASC" do
          expect(subject.to_a.index(missing_submission_file)).to \
            be < subject.to_a.index(another_missing_submission_file)
        end
      end

      describe "assignment association" do
        let(:another_submission_with_missing_file) { create(:submission, student: student3) } # some other assignment
        let(:cache_team_memberships) { team_membership; another_team_membership }

        context "submission file is associated with submission for that assignment" do
          it "returns the submission file" do
            expect(subject).to include(missing_submission_file)
          end
        end

        context "submission_file is associated with another assignment" do
          it "doesn't return the submission file" do
            expect(subject).not_to include(another_missing_submission_file)
          end
        end
      end
    end

    describe "#students_with_missing_binaries_on_team" do
      subject { assignment.students_with_missing_binaries_on_team(team) }

      describe "student team membership" do
        context "student is on the team" do
          it "returns students that have missing submission binaries for the assignment and are on the team" do
            expect(subject).to include(student1)
          end
        end

        context "student is not on the team" do
          it "returns students that have missing submission binaries for the assignment but are not on the team" do
            expect(subject).not_to include(student3)
          end
        end
      end

      describe "assignment association" do
        let(:cache_team_memberships) { team_membership; another_team_membership }
        let(:another_submission_with_missing_file) { create(:submission, student: student3) } # some other assignment

        it "doesn't return students that don't have a missing submission file for the assignment" do
          expect(subject).not_to include(student2)
        end
      end

      describe "ordering" do
        let(:cache_team_memberships) { team_membership; another_team_membership }

        it "orders the students by name" do
          expect(subject.first.submitter_directory_name <
            subject.last.submitter_directory_name).to be_truthy
        end
      end
    end
  end
end
