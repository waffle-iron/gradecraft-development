require "rails_spec_helper"

feature "editing a team challenge grade" do
  context "as a professor" do
    let(:course) { create :course, has_team_challenges: true }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:challenge) { create :challenge, name: "Team Challenge Name", course: course }
    let!(:team) { create :team, name: "Team Name", course: course }
    let!(:challenge_grade) { create :challenge_grade, team: team, challenge: challenge, score: 100 }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Team Challenges"
      end

      expect(current_path).to eq challenges_path

      within(".pageContent") do
        click_link "Team Challenge Name"
      end

      expect(current_path).to eq challenge_path(challenge.id)

      within(".pageContent") do
        click_link "Edit Grade"
      end

      expect(current_path).to eq edit_challenge_grade_path(challenge_grade)

      within(".pageContent") do
        fill_in("challenge_grade_score", with: 101)
        click_button "Update Grade"
      end
      expect(page).to have_notification_message("success", "Team Name's Grade for Team Challenge Name Team Challenge successfully updated")
    end
  end
end
