require "rails_spec_helper"

feature "deleting a badge" do
  context "as a professor" do
    let(:course) { create :course, has_badges: true}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course}

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Badges"
      end

      expect(current_path).to eq badges_path

      within(".pageContent") do
        click_link "Delete"
      end

      expect(page).to have_notification_message("success", "Fancy Badge Badge successfully deleted")
    end
  end
end
