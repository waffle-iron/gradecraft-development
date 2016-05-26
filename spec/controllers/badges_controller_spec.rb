require "rails_spec_helper"

describe BadgesController do
  before(:all) do
    @course = create(:course)
    @student = create(:user)
    @student.courses << @course
    @badge = create(:badge, course: @course)
  end

  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end

    before(:each) { login_user(@professor) }

    describe "GET index" do
      it "returns badges for the current course" do
        get :index
        expect(response).to render_template(:index)
      end
    end

    describe "GET show" do
      it "displays the badge page" do
        get :show, id: @badge.id
        expect(response).to render_template(:show)
      end
    end

    describe "GET new" do
      it "renders the new badge form" do
        get :new
        expect(assigns(:title)).to eq("Create a New badge")
        expect(assigns(:badge)).to be_a_new(Badge)
        expect(response).to render_template(:new)
      end
    end

    describe "GET edit" do
      it "renders the edit badge form" do
        get :edit, id: @badge.id
        expect(assigns(:title)).to eq("Editing #{@badge.name}")
        expect(assigns(:badge)).to eq(@badge)
        expect(response).to render_template(:edit)
      end
    end

    describe "POST create" do
      it "creates the badge with valid attributes"  do
        params = attributes_for(:badge)
        expect{ post :create, badge: params }.to change(Badge,:count).by(1)
      end

      it "manages file uploads" do
        Badge.delete_all
        params = attributes_for(:badge)
        params.merge! badge_files_attributes: {"0" => {"file" => [fixture_file("test_file.txt", "txt")]}}
        post :create, badge: params
        badge = Badge.where(name: params[:name]).last
        expect expect(badge.badge_files.count).to eq(1)
      end

      it "redirects to new form with invalid attributes" do
        expect{ post :create, badge: attributes_for(:badge, name: nil) }.to_not change(Badge,:count)
      end
    end

    describe "POST update" do
      before do
        @badge_2 = create(:badge, course: @course)
      end

      it "updates the badge" do
        params = { name: "new name" }
        post :update, id: @badge_2.id, badge: params
        expect(response).to redirect_to(badges_path)
        expect(@badge_2.reload.name).to eq("new name")
      end

      it "manages file uploads" do
        params = {badge_files_attributes: {"0" => {"file" => [fixture_file("test_file.txt", "txt")]}}}
        post :update, id: @badge_2.id, badge: params
        expect expect(@badge_2.badge_files.count).to eq(1)
      end

      it "redirects to edit form with invalid attributes" do
        params = { name: nil }
        post :update, id: @badge.id, badge: params
        expect(response).to render_template(:edit)
      end
    end

    describe "GET sort" do
      it "sorts the badges by params" do
        second_badge = create(:badge)
        @course.badges << second_badge
        params = [second_badge.id, @badge.id]
        post :sort, badge: params

        expect(@badge.reload.position).to eq(2)
        expect(second_badge.reload.position).to eq(1)
      end
    end

    describe "GET destroy" do
      it "destroys the badge" do
        another_badge = create :badge, course: @course
        expect{ get :destroy, id: another_badge }.to change(Badge,:count).by -1
      end
    end
  end

  context "as student" do
    before(:each) { login_user(@student) }

    describe "protected routes" do
      [
        :new,
        :create,
        :sort
      ].each do |route|
          it "#{route} redirects to root" do
            expect(get route).to redirect_to(:root)
          end
        end
    end

    describe "protected routes requiring id in params" do
      [
        :edit,
        :update,
        :destroy
      ].each do |route|
        it "#{route} redirects to root" do
          expect(get route, {id: "1"}).to redirect_to(:root)
        end
      end
    end
  end
end
