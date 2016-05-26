require "rails_spec_helper"

describe EarnedBadgesController do
  before(:all) do
    @course = create(:course)
    @student = create(:user)
    @student.courses << @course
  end
  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as a professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
      @badge = create(:badge, course: @course)
    end

    before(:each) do
      @earned_badge = create(:earned_badge, badge: @badge, student: @student)
      login_user(@professor)
    end

    describe "GET index" do
      it "redirects to the badge for the earned badge" do
        get :index, badge_id: @badge.id
        expect(response).to redirect_to(badge_path(@badge))
      end
    end

    describe "GET show" do
      it "returns the earned badge show page" do
        get :show, { id: @earned_badge.id, badge_id: @badge.id }
        expect(assigns(:earned_badge)).to eq(@earned_badge)
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "display the create form" do
        get :new, badge_id: @badge.id
        expect(assigns(:title)).to eq("Award #{@badge.name}")
        expect(assigns(:earned_badge)).to be_a_new(EarnedBadge)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "displays the edit form" do
        get :edit, {id: @earned_badge.id, badge_id: @badge.id}
        expect(assigns(:earned_badge)).to eq(@earned_badge)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the earned badge with valid attributes" do
        expect{ post :create, badge_id: @badge.id, earned_badge: { badge_id: @badge.id,
                                              student_id: @student.id,
                                              student_visible: true,
                                              feedback: "You did great!" }}.to \
          change(EarnedBadge.student_visible, :count).by(1)
        expect(response).to redirect_to badge_path(@badge)
      end

      it "doesn't create earned badges with invalid attributes" do
        expect{ post :create, badge_id: @badge.id, earned_badge: { badge_id: @badge.id,
                                                          student_id: nil,
                                                          student_visible: true,
                                                          feedback: "You rock!" }}.to_not \
          change(EarnedBadge,:count)
      end
    end

    describe "POST mass_earn" do
      before(:all) do
        @students = create_list(:user, 2)
        @student_ids = @students.collect(&:id)
      end

      subject { post :mass_earn, {id: @badge[:id], student_ids: @student_ids} }

      context "earned badges are created" do
        before do
          @earned_badges = @students.collect do |student|
            create(:earned_badge, student_id: student[:id], badge: @badge)
          end
        end

        it "redirects to the badge page" do
          allow(controller).to receive(:parse_valid_earned_badges) { @earned_badges }
          expect(subject).to redirect_to(badge_path(@badge))
        end

        it "redirects back to the edit page" do
          allow(controller).to receive(:parse_valid_earned_badges) { [] }
          expect(subject).to redirect_to(mass_award_badge_url(id: @badge))
        end
      end
    end

    describe "send_earned_badge_notifications" do
      before(:all) do
        @students = create_list(:user, 2)
        @student_ids = @students.collect(&:id)
      end

      before(:each) do
        @earned_badges = @students.collect do |student|
          create(:earned_badge, student_id: student.id, badge: @badge)
        end
        @controller = EarnedBadgesController.new
      end

      context "earned badges exist" do
        before(:each) do
          @controller.instance_variable_set(:@valid_earned_badges, @earned_badges)
        end

        it "should send a notification" do
          mail_responder = double("earned badge mail responder!!")
          allow(mail_responder).to receive(:deliver_now)
          allow(NotificationMailer).to receive(:earned_badge_awarded) { mail_responder }
          @earned_badges.each do |earned_badge|
            expect(NotificationMailer).to receive(:earned_badge_awarded).with(earned_badge[:id])
          end
          controller.instance_eval { send_earned_badge_notifications }
        end

        it "should record the notification in the environment log" do
          @earned_badges.each do |earned_badge|
            earned_badge_notification_message = "Sent an earned badge notification for EarnedBadge ##{earned_badge[:id]}"
            expect(controller.logger).to receive(:info).with(earned_badge_notification_message)
          end
          controller.instance_eval { send_earned_badge_notifications }
        end
      end

      context "no earned badges" do
        it "should not send any notifications" do
          @controller.instance_variable_set(:@valid_earned_badges, [])
          expect(NotificationMailer).not_to receive(:earned_badge_awarded)
        end
      end
    end

    describe "POST update" do
      it "updates the earned badge" do
        params = { badge_id: @badge.id, student_id: @student.id, feedback: "great!" }
        post :update, { id: @earned_badge.id, badge_id: @badge.id, earned_badge: params }
        expect(@earned_badge.reload.feedback).to eq("great!")
        expect(response).to redirect_to(badge_path(@badge))
      end

      it "renders the edit template if the update fails" do
        params = { badge_id: @badge.id, student_id: nil, feedback: "great!" }
        post :update, { id: @earned_badge.id, badge_id: @badge.id, earned_badge: params }
        expect(response).to render_template(:edit)
      end
    end

    describe "GET mass_edit" do
      it "assigns params" do
        get :mass_edit, id: @badge.id
        expect(assigns(:badge)).to eq(@badge)
        expect(assigns(:title)).to eq("Quick Award #{@badge.name}")
        expect(assigns(:students)).to eq([@student])
        expect(response).to render_template(:mass_edit)
      end

      describe "with teams" do
        it "assigns team and students for team" do
          # we verify only students on team assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          team = create(:team, course: @course)
          team.students << @student

          get :mass_edit, {id: @badge.id, team_id: team.id}
          expect(assigns(:team)).to eq(team)
          expect(assigns(:students)).to eq([@student])
        end
      end

      describe "with no team id in params" do
        it "assigns all students if no team supplied" do
          # we verify non-team members also assigned as @students
          other_student = create(:user)
          other_student.courses << @course

          get :mass_edit, id: @badge.id
          expect(assigns(:students)).to include(@student)
          expect(assigns(:students)).to include(other_student)
        end
      end

      describe "when badges can be earned multiple times" do
        it "assigns earned badges according to alphabetized students" do
          @student.update(last_name: "Zed")
          student2 = create(:user, last_name: "Alpha")
          student2.courses << @course

          get :mass_edit, id: @badge.id
          expect(assigns(:earned_badges).count).to eq(2)
          expect(assigns(:earned_badges)[0].student_id).to eq(student2.id)
          expect(assigns(:earned_badges)[1].student_id).to eq(@student.id)
        end

      end

      describe "when badges can only be earned once" do
        it "builds a new one if it hasn't been earned" do
          @badge.can_earn_multiple_times = false
          @badge.save

          get :mass_edit, id: @badge.id
          expect(assigns(:earned_badges)).to eq([@earned_badge])
          expect(response).to render_template(:mass_edit)
        end
      end
    end

    describe "GET destroy" do
      it "destroys the earned badge" do
        expect{ get :destroy, { id: @earned_badge, badge_id: @badge.id } }.to change(EarnedBadge,:count).by(-1)
      end
    end
  end

  context "as student" do
    before { login_user(@student) }

    describe "protected routes" do
      [
        :index,
        :new,
        :create
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route, {badge_id: 1}).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :edit,
        :show,
        :update,
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {badge_id: 1, id: "1"}).to redirect_to(:root)
        end
      end
    end
  end
end
