require "rails_spec_helper"

feature "downloading final grades file" do
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
        click_link "Course Data Exports"
      end

      within(".pageContent") do
        click_link "Final Grades"
      end

      expect(page.response_headers["Content-Type"]).to eq("text/csv")

      expect(page).to have_content "First Name,Last Name,Email,Username,Score,Grade,Level,Earned Badge #,GradeCraft ID"
    end
  end
end
