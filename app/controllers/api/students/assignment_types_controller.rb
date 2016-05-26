class API::Students::AssignmentTypesController < ApplicationController
  include PredictorData

  before_filter :ensure_staff?

  # GET api/students/:student_id/assignment_types
  def index
    @student = User.find(params[:student_id])
    @update_weights = false

    @assignment_types = predictor_assignment_types
    render template: "api/assignment_types/index"
  end
end
