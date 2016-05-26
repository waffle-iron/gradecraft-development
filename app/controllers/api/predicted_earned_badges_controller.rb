class API::PredictedEarnedBadgesController < ApplicationController
  include PredictorData

  before_filter :ensure_student?, only: [:update]

  # GET api/predicted_earned_badges
  def index
    if current_user_is_student?
      @student = current_student
      @update_badges = true
    else
      @student = NullStudent.new
      @update_badges = false
    end
    @badges = predictor_badges(@student)
  end

  # POST api/predicted_earned_badges/:id
  def update
    prediction = PredictedEarnedBadge.where(
      student: current_student,
      id: params[:id]
    ).first

    prediction.predicted_times_earned = params[:predicted_times_earned]
    prediction.save

    # This should be extracted with the rest of the event_loggers
    PredictorEventJob.new(
      data: badge_predictor_event_attrs(prediction.badge, prediction.valid?)
    ).enqueue

    if prediction.valid?
      render json: {
        id: prediction.id,
        predicted_times_earned: prediction.predicted_times_earned
      }
    else
      render json: {
        errors:  prediction.errors.full_messages
        },
        status: 400
    end
  end

  private

  # This should be extracted with the rest of the event_loggers
  def badge_predictor_event_attrs(badge, prediction_saved)
    {
      prediction_type: "badge",
      course_id: current_course.id,
      user_id: current_user.id,
      student_id: current_student.try(:id),
      user_role: current_user.role(current_course),
      badge_id: badge.id,
      predicted_earns: params[:predicted_times_earned],
      multiple_earns_possible: badge.can_earn_multiple_times,
      predicted_points: badge_predicted_points,
      point_value_per_badge: badge.point_total,
      created_at: Time.now,
      prediction_saved_successfully: prediction_saved
    }
  end

  def badge_predicted_points
    @badge.point_total * params[:predicted_times_earned] rescue nil
  end
end
