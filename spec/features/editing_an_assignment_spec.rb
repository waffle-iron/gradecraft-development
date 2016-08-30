require "rails_spec_helper"

feature "editing an assignment" do
  context "as a professor" do
    let(:course) { create :course, assignment_term: "Assignment"}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:assignment_type) { create :assignment_type, name: "Assignment Type Name", course: course }
    let!(:assignment) { create :assignment, name: "Assignment Name", course: course, assignment_type: assignment_type }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Assignments"
      end

      expect(current_path).to eq assignments_path

      within(".pageContent") do
        find(".assignment-type-name").click
        click_link "Assignment Name"
      end

      expect(current_path).to eq assignment_path(assignment.id)

      within(".context_menu") do
        click_link "Edit"
      end

      within(".pageContent") do
        fill_in "Name", with: "Edited Assignment Name"
        click_button "Update Assignment"
      end

      expect(page).to have_notification_message("success", "Assignment Edited Assignment Name successfully updated")
    end
  end
end
