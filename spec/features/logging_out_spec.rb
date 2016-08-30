require "rails_spec_helper"

feature "logging out" do
  let(:password) { "p@ssword" }

  context "as a student" do
    let!(:course_membership) { create :student_course_membership, user: user }
    let(:user) { create :user, password: password }

    before { visit new_user_session_path }

    before(:each) do
      LoginPage.new(user).submit({ password: password })
    end

    scenario "successfully" do

      within("#account-info") do
        click_link "Logout"
      end

      expect(current_path).to eq root_path
      expect(page).to have_notification_message("success", "You are now logged out.")
    end

  end

end
