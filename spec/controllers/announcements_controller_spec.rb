require "rails_spec_helper"

describe AnnouncementsController do
  context "as a student" do
    before(:all) do
      @course = create :course
      @student = create :user
      CourseMembership.create(course: @course, user: @student, role: "student")
    end
    before(:each) do
      session[:course_id] = @course.id
      login_user(@student)
    end

    describe "GET #show" do
      it "marks the announcement as read by the student" do
        announcement = create :announcement, course: @course
        get :show, id: announcement.id
        expect(announcement.read?(@student)).to be_truthy
      end
    end

    describe "GET #new" do
      it "should not allow a student to try and create an announcement" do
        expect { get :new }.to raise_error CanCan::AccessDenied
      end
    end

    describe "POST #create" do
      it "should not allow a student to create an announcement" do
        expect { post :create, announcement: { title: "New Tour", body: "Test" } }.to \
          raise_error CanCan::AccessDenied
      end
    end
  end

  context "as a professor" do
    before(:all) do
      @course = create :course
      @professor = create :user
      CourseMembership.create course: @course, user: @professor, role: "professor"
    end

    before(:each) do
      login_user(@professor)
      session[:course_id] = @course.id
    end

    describe "GET #index" do
      let!(:announcement) { create :announcement, course_id: @course.id }
      let!(:non_course_announcement) { create :announcement }

      it "lists the announcements that are available for that course" do
        get :index
        expect(assigns(:announcements)).to eq [announcement]
      end
    end

    describe "POST #create" do
      let(:body) { Faker::Lorem.sentence(3) }

      context "with a successful announcement" do
        it "creates a new announcement" do
          post :create, announcement: { title: "New Tour", body: body }
          announcement = Announcement.unscoped.last
          expect(announcement.title).to eq "New Tour"
          expect(announcement.body).to eq body
          expect(announcement.course).to eq @course
          expect(announcement.author).to eq @professor
        end

        it "redirects back to the announcements page" do
          post :create, announcement: { title: "New Tour", body: body }
          expect(response).to redirect_to announcements_path
        end

        it "sends out the announcement to all the students in the course" do
          student = create :user
          CourseMembership.create! course_id: @course.id,
            user_id: student.id, role: "student"
          expect {
            post :create, announcement: { title: "New Tour", body: body }
          }.to change  { ActionMailer::Base.deliveries.count }.by 2
        end
      end

      context "with an invalid announcement" do
        it "renders view with the errors" do
          post :create, announcement: { title: "", body: body }
          expect(response).to render_template :new
        end
      end
    end
  end
end
