require "rails_spec_helper"

feature "deleting a course" do
  context "as an admin" do
    let(:course) { create :course, name: "Course Name" }
    let(:course_2) { create :course, name: "Course Name" }
    let!(:course_membership) { create :admin_course_membership, user: admin, course: course }
    let!(:course_membership_2) { create :admin_course_membership, user: admin, course: course_2 }
    let(:admin) { create :user }

    before(:each) do
      login_as admin
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "My Courses"
      end

      expect(current_path).to eq courses_path

      within(".pageContent") do
        click_link "course-id-#{course.id}"
      end

      expect(page).to have_notification_message("success", "Course Course Name successfully deleted")
    end
  end
end
