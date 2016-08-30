require "rails_spec_helper"

feature "editing a team" do
  context "as a professor" do
    let(:course) { create :course, has_teams: true }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:team) { create :team, name: "Team Name", course: course }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Teams"
      end

      expect(current_path).to eq teams_path

      within(".pageContent") do
        click_link "Team Name"
      end

      expect(current_path).to eq team_path(team.id)

      within(".context_menu") do
        click_link "Edit"
      end

      within(".pageContent") do
        fill_in "Name", with: "Edited Team Name"
        click_button "Update Team"
      end

      expect(page).to have_notification_message("success", "Team Edited Team Name successfully updated")
    end
  end
end
