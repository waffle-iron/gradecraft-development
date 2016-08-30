require "rails_spec_helper"

feature "creating a new user", focus: true do
  context "as an administrator" do
    let!(:course_membership) { create :admin_course_membership, user: admin }
    let(:admin) { create :user }

    before(:each) do
      login_as admin
      visit new_user_path
    end

    context "for an existing GradeCraft student" do
      scenario "successfully" do
        user = create(:user)
        within(".pageContent #tab1") do
          NewUserPage.new(user)
            .submit(courses: [course_membership.course])
        end

        expect(current_path).to eq students_path
        expect(page).to have_notification_message "success", "#{course_membership.course.student_term} #{user.name} was successfully created!"

        result = user.reload
        expect(result.course_memberships.count).to eq 1
        expect(result.course_memberships.first.course).to eq course_membership.course
        expect(result.course_memberships.first.role).to eq "student"
      end
    end

    context "for a UM student" do
      scenario "successfully" do
        username = Faker::Internet.user_name
        user = build(:user, email: "#{username}@umich.edu")
        within(".pageContent #tab2") do
          NewUserPage.new(user)
            .submit(internal: true, courses: [course_membership.course])
        end

        expect(current_path).to eq students_path
        expect(page).to have_notification_message "success", "#{course_membership.course.student_term} #{user.name} was successfully created!"

        result = User.unscoped.last
        expect(result.first_name).to eq user.first_name
        expect(result.last_name).to eq user.last_name
        expect(result.email).to eq user.email
        expect(result.username).to eq username
        expect(result.kerberos_uid).to eq username
        expect(result.crypted_password).to be_nil
        expect(result).to be_activated
      end

      scenario "with a non-umich email address" do
        user = build(:user)
        within(".pageContent #tab2") do
          NewUserPage.new(user)
            .submit(internal: true, courses: [course_membership.course])
        end

        expect(current_path).to eq users_path
        expect(page).to have_notification_message :alert, "Email must be a University of Michigan email"
      end
    end
  end
end
