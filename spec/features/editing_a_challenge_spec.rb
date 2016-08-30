require "rails_spec_helper"

feature "editing a challenge" do
  context "as a professor" do
    let(:course) { create :course, has_team_challenges: true}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:challenge) { create :challenge, name: "Team Challenge Name", course: course }

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

      within(".context_menu") do
        click_link "Edit"
      end

      within(".pageContent") do
        fill_in "Name", with: "Edited Team Challenge Name"
        click_button "Update Team Challenge"
      end

      expect(page).to have_notification_message("success", "Challenge Edited Team Challenge Name successfully updated")
    end
  end
end
