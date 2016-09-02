class GradesController < ApplicationController
  respond_to :html, :json
  before_filter :ensure_staff?,
    except: [:feedback_read, :show, :predict_score, :async_update]
  before_filter :ensure_student?, only: [:feedback_read, :predict_score]
  before_filter :save_referer, only: :edit

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == "application/json" }

  # GET /grades/:id
  def show
    @grade = Grade.find params[:id]
    # rubocop:disable AndOr
    redirect_to @grade.assignment and return if current_user_is_student?

    name = @grade.group.nil? ? @grade.student.name : @grade.group.name
    @title = "#{name}'s Grade for #{@grade.assignment.name}"
  end

  # GET /grades/:id/edit
  def edit
    @grade = Grade.find params[:id]
    @title = "Editing #{@grade.student.name}'s Grade "\
      "for #{@grade.assignment.name}"
    @badges = @grade.student.earnable_course_badges_for_grade(@grade)
    @submission = @grade.student.submission_for_assignment(@grade.assignment)
  end

  # To avoid duplicate grades, we don't supply a create method. Update will
  # create a new grade if none exists, and otherwise update the existing grade
  # PUT /grades/:id
  def update
    grade = Grade.find params[:id]

    if grade.update_attributes grade_params.merge(graded_at: DateTime.now,
                                                  graded_by_id: current_user.id)
      if GradeProctor.new(grade).viewable?
        GradeUpdaterJob.new(grade_id: grade.id).enqueue
      end

      if params[:redirect_to_next_grade].present?
        path = path_for_next_grade grade
      else
        path = assignment_path(grade.assignment)
      end
      redirect_to path,
        notice: "#{grade.student.name}'s #{grade.assignment.name} was successfully updated"
    else # failure
      redirect_to edit_grade_path(grade),
        alert: "#{grade.student.name}'s #{grade.assignment.name} was not successfully "\
          "submitted! Please try again."
    end
  end

  # POST /grades/:id/remove
  # This is the method used when faculty delete a grade
  # it preserves the predicted grade
  def remove
    grade = Grade.find(params[:id])

    if grade.clear_grade!
      score_recalculator(grade.student)
      redirect_to grade.assignment,
        notice: "#{grade.student.name}'s #{grade.assignment.name} grade was successfully deleted."
    else
      redirect_to grade.assignment, notice: grade.errors.full_messages, status: 400
    end
  end

  # POST /grades/:id/exclude
  def exclude
    grade = Grade.find(params[:id])
    grade.excluded_from_course_score = true
    grade.excluded_by_id = current_user.id
    grade.excluded_at = Time.now
    if grade.save
      score_recalculator(grade.student)
      redirect_to student_path(grade.student), notice: "#{ grade.student.name }'s
      #{ grade.assignment.name } grade was successfully excluded from their
      total score."
    else
      redirect_to student_path(grade.student), alert: "#{ grade.student.name }'s
      #{ grade.assignment.name } grade was not successfully excluded from their
      total score - please try again."
    end
  end

  # POST /grades/:id/include
  def include
    grade = Grade.find(params[:id])
    grade.excluded_from_course_score = false
    grade.excluded_by_id = nil
    grade.excluded_at = nil
    if grade.save
      score_recalculator(grade.student)
      redirect_to student_path(grade.student), notice: "#{ grade.student.name }'s
      #{ grade.assignment.name } grade was successfully re-added to their total
      score."
    else
      redirect_to student_path(grade.student), alert: "#{ grade.student.name }'s
      #{ grade.assignment.name } grade was not successfully re-added to their
      total score - please try again."
    end
  end

  # DELETE /grades/:id
  def destroy
    grade = Grade.find(params[:id])
    authorize! :destroy, grade
    grade.destroy
    score_recalculator(grade.student)

    redirect_to assignment_path(grade.assignment),
      notice: "#{grade.student.name}'s #{grade.assignment.name} grade was "\
              "successfully deleted."
  rescue CanCan::AccessDenied
    # This is handled here so that a different redirect path can be specified
    redirect_to assignment_path(grade.assignment)
  end

  # POST /grades/:id/feedback_read
  def feedback_read
    grade = Grade.find params[:id]
    authorize! :update, grade, student_logged: false
    grade.feedback_read!
    redirect_to assignment_path(grade.assignment),
      notice: "Thank you for letting us know!"
  end

  private

  def grade_params
    params.require(:grade).permit :_destroy, :score, :adjustment_points, :adjustment_points_feedback,
      :assignment_id, :assignment_type_id, :assignments_attributes, :course_id,
      :earned_badges_attributes, :excluded_by_id, :excluded_at, :excluded_from_course_score,
      :feedback, :feedback_read, :feedback_read_at, :feedback_reviewed, :feedback_reviewed_at,
      :final_points, :grade_file_ids, :grade_files_attributes, :graded_at, :graded_by_id,
      :group_id, :group_type, :is_custom_value, :pass_fail_status,
      :full_points, :raw_points, :student_id, :submission_id, :task_id, :team_id, :status,
      grade_files_attributes: [:id, file: []]
  end

  def temp_view_context
    @temp_view_context ||= ApplicationController.new.view_context
  end

  def serialized_init_data
    JbuilderTemplate.new(temp_view_context).encode do |json|
      json.grade do
        json.partial! "grades/grade", grade: @grade, assignment: @assignment
      end

      json.badges do
        json.partial! "grades/badges", badges: @badges, student_id: @student.id
      end

      json.assignment do
        json.partial! "grades/assignment", assignment: @assignment
      end

      json.assignment_score_levels do
        json.partial! "grades/assignment_score_levels", assignment_score_levels: @assignment_score_levels
      end
    end.to_json
  end

  def serialized_criterion_grades
    CriterionGrade.where({ student_id: params[:student_id],
                        assignment_id: params[:assignment_id],
                        criterion_id: rubric_criteria_with_levels.collect {|criterion| criterion[:id] } })
                        .select(:id, :criterion_id, :level_id, :comments).to_json
  end

  def score_recalculator(student)
    ScoreRecalculatorJob.new(user_id: student.id,
                           course_id: current_course.id).enqueue
  end

  def rubric_criteria_with_levels
    @rubric_criteria_with_levels ||= @rubric.criteria.ordered.includes(:levels)
  end

  def path_for_next_grade(grade)
    next_student = grade.assignment.next_ungraded_student(grade.student)
    return assignment_path(grade.assignment) unless next_student.present?
    return edit_grade_path(
      Grade.find_or_create(grade.assignment.id, next_student.id)
    )
  end
end
