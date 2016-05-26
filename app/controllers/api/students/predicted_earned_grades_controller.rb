class API::Students::PredictedEarnedGradesController < ApplicationController

  before_filter :ensure_staff?

  # GET api/students/:student_id/predicted_earned_grades
  def index
    student = User.find(params[:student_id])
    @assignments = PredictedAssignmentCollectionSerializer.new current_course.assignments, current_user, student
    render template: "api/predicted_earned_grades/index"
  end
end
