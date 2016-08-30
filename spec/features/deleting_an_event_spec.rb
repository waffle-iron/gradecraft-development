require "rails_spec_helper"

feature "deleting an event" do
  context "as a professor" do
    let(:course) { create :course }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:event) { create :event, course: course, name: "Event Name", due_at: Date.today }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Calendar Events"
      end

      expect(current_path).to eq events_path

      within(".pageContent") do
        click_link "Delete"
      end

      expect(page).to have_notification_message("success", "Event Name successfully deleted")
    end
  end
end
