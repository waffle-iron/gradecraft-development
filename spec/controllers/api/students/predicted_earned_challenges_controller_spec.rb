require "rails_spec_helper"

describe API::Students::PredictedEarnedChallengesController do
  let(:world) { World.create.with(:course, :student, :team, :challenge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
        allow(world.course).to receive(:add_team_score_to_student).and_return(true)
        world.team.students << world.student
      end

      it "adds the prediction data to the challenge model with a zero points prediction" do
        prediction = create(:predicted_earned_challenge, challenge: world.challenge, student: world.student)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:challenges).last.prediction).to eq({ id: prediction.id, predicted_points: 0 })
      end

      it "adds visible grades to the challenge data" do
        grade = create(:graded_challenge_grade, challenge: world.challenge, team: world.team)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:challenges).last.grade).to eq({score: grade.score })
      end

      it "adds grades as nil when not visible to student" do
        world.challenge.update(release_necessary: true)
        grade = create(:grades_not_released_challenge_grade, challenge: world.challenge, team: world.team)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:challenges).last.grade).to eq({ score: nil })
      end

      it "assigns the challenges with no call to update" do
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:student)).to eq(world.student)
        expect(assigns(:challenges)[0].attributes.length).to eq(predictor_challenge_attributes.length)
        predictor_challenge_attributes do |attr|
          expect(assigns(:challenges)[0][attr]).to eq(world.challenge[attr])
        end
        expect(assigns(:update_challenges)).to be_falsey
        expect(response).to render_template("api/predicted_earned_challenges/index")
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
