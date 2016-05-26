class API::Students::PredictedEarnedBadgesController < ApplicationController
  include PredictorData

  before_filter :ensure_staff?

  # GET api/students/:student_id/predicted_earned_badges
  def index
    @student = User.find(params[:student_id])
    @update_badges = false
    @badges = predictor_badges(@student)
    render template: "api/predicted_earned_badges/index"
  end
end
