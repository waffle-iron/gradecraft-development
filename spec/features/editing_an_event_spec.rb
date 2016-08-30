require "rails_spec_helper"

feature "editing an event" do
  context "as a professor" do
    let(:course) { create :course}
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
        click_link "Event Name"
      end

      expect(current_path).to eq event_path(event.id)

      within(".context_menu") do
        click_link "Edit"
      end

      expect(current_path).to eq edit_event_path(event.id)

      within(".pageContent") do
        fill_in "Name", with: "Edited Event Name"
        click_button "Update Event"
      end

      expect(page).to have_notification_message("success", "Event Edited Event Name was successfully updated")
    end
  end
end
