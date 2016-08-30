require "rails_spec_helper"

feature "creating a new assignment" do
  context "as a professor" do
    let(:course) { create :course, name: "Course Name", assignment_term: "Assignment"}
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:assignment_type) { create :assignment_type, course: course, name: "Assignment Type Name"}

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "Assignments"
      end

      within(".assignments") do
        click_link "New Assignment"
      end

      expect(current_path).to eq new_assignment_path

      within(".pageContent") do
        select "Assignment Type Name", from: "assignment_assignment_type_id"
        fill_in "Name", with: "New Assignment Name"
        click_button "Create Assignment"
      end

      expect(page).to have_notification_message("success", "Assignment New Assignment Name successfully created")
    end
  end
end
