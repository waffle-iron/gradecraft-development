require "rails_spec_helper"

feature "awarding many earned badges at once" do
  context "as a professor" do
    let(:course) { create :course, has_badges: true }
    let!(:course_membership) { create :professor_course_membership, user: professor, course: course }
    let(:professor) { create :user }
    let!(:badge) { create :badge, name: "Fancy Badge", course: course}
    let(:student) { create :user, first_name: "Hermione", last_name: "Granger" }
    let(:student_2) { create :user, first_name: "Ron", last_name: "Weasley" }
    let!(:course_membership_2) { create :student_course_membership, user: student, course: course }
    let!(:course_membership_3) { create :student_course_membership, user: student_2, course: course }

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
        click_link "Quick Award"
      end

      expect(current_path).to eq mass_edit_badge_earned_badges_path(badge)

      within(".pageContent") do
        find(:css, "#student-id-#{student.id}").set(true)
        find(:css, "#student-id-#{student_2.id}").set(true)
        click_button "Award"
      end
      expect(page).to have_notification_message("success", "The Fancy Badge Badge was successfully awarded 2 times")
    end
  end
end
