require "rails_spec_helper"

describe API::PredictedEarnedChallengesController do
  let(:world) { World.create.with(:course, :student, :team, :challenge) }
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
          expect(assigns(:update_challenges)).to be_falsey
        end
      end
    end
  end

  context "as student" do
    before do
      login_user(world.student)
      allow(controller).to receive(:current_course).and_return(world.course)
      allow(world.course).to receive(:add_team_score_to_student).and_return(true)
      allow(world.student).to receive(:team_for_course).and_return(world.team)
    end

    describe "GET index" do
      it "assigns the challenges with call to update" do
        get :index, format: :json, id: world.student.id
        expect(assigns(:student)).to eq(world.student)
        expect(assigns(:challenges)[0].attributes.length).to eq(predictor_challenge_attributes.length)
        predictor_challenge_attributes do |attr|
          expect(assigns(:challenges)[0][attr]).to eq(world.challenge[attr])
        end
        expect(assigns(:update_challenges)).to be_truthy
        expect(response).to render_template(:index)
      end

      it "adds the prediction data to the challenge data" do
        prediction = create(:predicted_earned_challenge, challenge: world.challenge, student: world.student)
        get :index, format: :json, id: world.student.id
        expect(assigns(:challenges)[0].prediction).to eq({ id: prediction.id, predicted_points: prediction.predicted_points })
      end

      it "adds visible grades to the challenge data" do
        grade = create(:graded_challenge_grade, challenge: world.challenge, team: world.team)
        get :index, format: :json, id: world.student.id
        expect(assigns(:challenges)[0].grade).to eq({ score: grade.score })
      end

      it "adds grades as nil when not visible to student" do
        world.challenge.update(release_necessary: true)
        grade = create(:grades_not_released_challenge_grade, challenge: world.challenge, team: world.team)
        get :index, format: :json, id: world.student.id
        expect(assigns(:challenges)[0].grade).to eq({ score: nil })
      end
    end

    describe "PUT update" do
      it "updates the predicted points for a challenge" do
        predicted_earned_challenge = create(:predicted_earned_challenge, challenge: world.challenge, student: world.student)
        predicted_points = (world.challenge.point_total * 0.75).to_i
        put :update, id: predicted_earned_challenge, predicted_points: predicted_points, format: :json
        expect(PredictedEarnedChallenge.where(student: world.student, challenge: world.challenge).first.predicted_points).to eq(predicted_points)
        expect(JSON.parse(response.body)).to eq({"id" => predicted_earned_challenge.id, "predicted_points" => predicted_points})
      end

      it "renders a 404 if prediction not found" do
        put :update, id: 0, predicted_points: 0, format: :json
        expect(response.status).to eq(404)
      end
    end
  end

  # helper methods:
  def predictor_challenge_attributes
    [
      :id,
      :name,
      :description,
      :point_total,
      :visible
    ]
  end
end
