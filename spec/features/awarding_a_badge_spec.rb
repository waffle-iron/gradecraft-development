require "rails_spec_helper"

feature "awarding a badge" do
  context "as a professor" do
    let(:course) { create :course, badge_setting: true }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course}
    let(:student) { create :user, first_name: "Hermione", last_name: "Granger" }
    let!(:course_membership_2) { create :student_course_membership, user: student, course: course }

    before(:each) do
      login_as professor
      visit dashboard_path
    end

    scenario "successfully" do
      within(".sidebar-container") do
        click_link "badges"
      end

      expect(current_path).to eq badges_path

      within(".pageContent") do
        click_link "Award"
      end

      expect(current_path).to eq new_badge_earned_badge_path(badge)

      within(".pageContent") do
        select "Hermione Granger", from: "earned_badge_student_id"
        click_button "Award badge"
      end
      expect(page).to have_notification_message("notice", "The Fancy Badge badge was successfully awarded to Hermione Granger")
    end
  end
end
