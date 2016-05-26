class AssignmentTypeWeightsController < ApplicationController

  before_filter :ensure_student?, only: [:update]

  # Students set their assignment type weights all at once
  def mass_edit
    @title =
      "Editing My #{term_for :weight} Choices" if current_user_is_student?
    @title =
      "Editing #{current_student.name}'s #{term_for :weight} Choices" if current_user_is_staff?
    @assignment_types = current_course.assignment_types
    respond_with @form =
      AssignmentTypeWeightForm.new(current_student, current_course)
  end

  def mass_update
    @form = AssignmentTypeWeightForm.new(current_student, current_course)

    @form.update_attributes(student_params)

    if @form.save
      if current_user_is_student?
        redirect_to syllabus_path, notice: "You have successfully updated your
          #{(term_for :weight).titleize} choices!"
      else
        redirect_to multiplier_choices_path,
          notice: "You have successfully updated #{current_student.name}'s
            #{(term_for :weight).capitalize} choices."
      end
    else
      respond_to do |format|
        if current_user_is_student?
          format.html { render action: "mass_edit" }
        else
          format.html {
            render action: "mass_edit", student_id: current_student
          }
        end
      end
    end
  end

  # Updates weights from the predictor
  def update
    assignment_type = current_course.assignment_types.find(params[:id])
    weight = params[:weight]
    if assignment_type && weight && assignment_type.student_weightable?
      assignment_type_weight = AssignmentTypeWeight.new(current_student,
        assignment_type)
      assignment_type_weight.weight = weight
    end
    respond_to do |format|
      format.json do
        if assignment_type_weight && assignment_type_weight.save
          render json: { assignment_type: assignment_type.id,
            weight: assignment_type.weight_for_student(current_student)
          }
        else
          render json: {
            errors:  "Unable to update assignment type weight"
            }, status: 400
        end
      end
    end
  end

  private

  def student_params
    params.require(:student).permit(assignment_type_weights_attributes:
      [:assignment_type_id, :weight])
  end
end
