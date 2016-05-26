require "rails_spec_helper"

describe Students::BadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do

    before(:each) do
      login_user(professor)
      allow(controller).to receive(:current_student).and_return(world.student)
    end

    describe "GET index" do
      it "returns badges for the current course" do
        get :index, student_id: world.student.id
        expect(response).to render_template("badges/index")
      end
    end

    describe "GET show" do
      it "displays the badge page" do
        get :show, student_id: world.student.id, id: world.badge.id
        expect(response).to render_template("badges/show")
      end
    end
  end
end
