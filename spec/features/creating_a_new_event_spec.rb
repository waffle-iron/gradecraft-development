require "rails_spec_helper"

feature "creating a new event" do
  context "as a professor" do
    let(:course) { create :course }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Calendar Events"
      end

      within(".context_menu") do
        click_link "New Event"
      end

      expect(current_path).to eq new_event_path

      within(".pageContent") do
        fill_in "Name", with: "New Event"
        click_button "Create Event"
      end

      expect(page).to have_notification_message("success", "Event New Event was successfully created")
    end
  end
end
