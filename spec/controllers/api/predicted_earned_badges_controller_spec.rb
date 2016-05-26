require "rails_spec_helper"

describe API::PredictedEarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      context "with no student" do
        it "assigns student as null student and no call to update" do
          get :index, format: :json
          expect(assigns(:student).class).to eq(NullStudent)
          expect(assigns(:update_badges)).to be_falsey
        end
      end
    end
  end

  context "as student" do
    before(:each) { login_user(world.student) }

    describe "GET index" do
      it "assigns the student and badges with the call to update" do
        get :index, format: :json, id: world.student.id
        expect(assigns(:student)).to eq(world.student)
        world.badge.reload
        predictor_badge_attributes.each do |attr|
          expect(assigns(:badges)[0][attr]).to eq(world.badge[attr])
        end
        expect(assigns(:update_badges)).to be_truthy
        expect(response).to render_template(:index)
      end

      it "adds the prediction data to the badge model" do
        prediction = create(:predicted_earned_badge, badge: world.badge, student: world.student)
        get :index, format: :json, id: world.student.id
        expect(assigns(:badges)[0].prediction).to eq({ id: prediction.id, predicted_times_earned: prediction.predicted_times_earned })
      end

      it "adds the prediction data to the badge model with prediction no less than earned" do
        prediction = create(:predicted_earned_badge, badge: world.badge, student: world.student, predicted_times_earned: 4)
        get :index, format: :json, id: world.student.id
        expect(assigns(:badges)[0].prediction).to eq({ id: prediction.id, predicted_times_earned: 4 })
      end
    end

    describe "PUT update" do
      it "updates the predicted times earned for a badge" do
        peb = create(:predicted_earned_badge, badge: world.badge, student: world.student)
        predicted_times_earned = 4
        put :update, id: peb.id, predicted_times_earned: predicted_times_earned, format: :json
        expect(PredictedEarnedBadge.where(student: world.student, badge: world.badge).first.predicted_times_earned).to eq(4)
        expect(JSON.parse(response.body)).to eq({"id" => peb.id, "predicted_times_earned" => predicted_times_earned})
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
