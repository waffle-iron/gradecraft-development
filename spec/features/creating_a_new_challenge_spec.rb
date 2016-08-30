require "rails_spec_helper"

feature "creating a new challenge" do
  context "as a professor" do
    let(:course) { create :course, has_team_challenges: true}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Team Challenges"
      end

      within(".context_menu") do
        click_link "New Team Challenge"
      end

      expect(current_path).to eq new_challenge_path

      within(".pageContent") do
        fill_in "Name", with: "New Team Challenge Name"
        click_button "Create Team Challenge"
      end

      expect(page).to have_notification_message("success", "Challenge New Team Challenge Name successfully created")
    end
  end
end
