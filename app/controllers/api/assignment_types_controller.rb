class API::AssignmentTypesController < ApplicationController
  include PredictorData

  # GET api/assignment_types
  def index
    if current_user_is_student?
      @student = current_student
      @update_weights = true
    else
      @student = NullStudent.new
      @update_weights = false
    end
    @assignment_types = predictor_assignment_types
  end
end
