class API::Students::PredictedEarnedChallengesController < ApplicationController
  include PredictorData

  before_filter :ensure_staff?

  # GET api/students/:student_id/predicted_earned_challenges
  def index
    @student = User.find(params[:student_id])
    @update_challenges = false
    @challenges = predictor_challenges(@student)
    render template: "api/predicted_earned_challenges/index"
  end
end
