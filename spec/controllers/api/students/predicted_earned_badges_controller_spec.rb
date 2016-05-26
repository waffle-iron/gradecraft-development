require "rails_spec_helper"

describe API::Students::PredictedEarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      it "assigns the badges with no call to update" do
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:student)).to eq(world.student)
        predictor_badge_attributes do |attr|
          expect(assigns(:badges)[0][attr]).to eq(world.badge[attr])
        end
        expect(assigns(:update_badges)).to be_falsey
        expect(response).to render_template("api/predicted_earned_badges/index")
      end
    end
  end

  # helper methods:
  def predictor_badge_attributes
    [
      :id,
      :name,
      :description,
      :point_total,
      :visible,
      :visible_when_locked,
      :can_earn_multiple_times,
      :position,
      :icon
    ]
  end
end
