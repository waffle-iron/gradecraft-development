class GradesController < ApplicationController
  respond_to :html, :json
  before_filter :set_assignment, only: [:edit, :update]
  before_filter :ensure_staff?,
    except: [:feedback_read, :show, :predict_score, :async_update]
  before_filter :ensure_student?, only: [:feedback_read, :predict_score]
  before_filter :save_referer, only: :edit

  protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == "application/json" }

  # GET /grades/:id
  def show
    @grade = Grade.find params[:id]

    redirect_to @grade.assignment and return if current_user_is_student?

    name = @grade.group.nil? ? @grade.student.name : @grade.group.name
    @title = "#{name}'s Grade for #{@grade.assignment.name}"
  end

  # GET /assignments/:assignment_id/grade/edit?student_id=:id
  def edit
    @student = current_student

    @grade = Grade.find_or_create(@assignment.id, @student.id)
    @title = "Editing #{@student.name}'s Grade for #{@assignment.name}"

    @submission = @student.submission_for_assignment(@assignment)

    @badges = @student.earnable_course_badges_for_grade(@grade)
    @assignment_score_levels =
      @assignment.assignment_score_levels.order_by_value

    if @assignment.grade_with_rubric?
      @rubric = @assignment.rubric
      @criterion_grades = serialized_criterion_grades
      # This is sent to the Angular controlled submit button
      @return_path =
        URI(request.referer).path + "?student_id=#{current_student.id}"
    end

    @serialized_init_data = serialized_init_data
  end

  # To avoid duplicate grades, we don't supply a create method. Update will
  # create a new grade if none exists, and otherwise update the existing grade
  # PUT /assignments/:assignment_id/grade
  def update
    @grade = Grade.find_or_create(@assignment.id, current_student.id)

    if @grade.update_attributes params[:grade].merge(graded_at: DateTime.now,
        instructor_modified: true)

      if GradeProctor.new(@grade).viewable?
        grade_updater_job = GradeUpdaterJob.new(grade_id: @grade.id)
        grade_updater_job.enqueue
      end

      if session[:return_to].present?
        redirect_to session[:return_to], notice: "#{@grade.student.name}'s #{@assignment.name} was successfully updated"
      else
        redirect_to assignment_path(@assignment), notice: "#{@grade.student.name}'s #{@assignment.name} was successfully updated"
      end

    else # failure
      redirect_to edit_assignment_grade_path(@assignment, student_id: @grade.student.id), alert: "#{@grade.student.name}'s #{@assignment.name} was not successfully submitted! Please try again."
    end
  end

  # POST /grades/earn_student_badges
  def earn_student_badges
    @earned_badges = EarnedBadge.create params[:earned_badges]
    render json: @earned_badges
  end

  # DELETE grade/:grade_id/earned_badges
  def delete_all_earned_badges
    if EarnedBadge.exists?(grade_id: params[:grade_id])
      EarnedBadge.where(grade_id: params[:grade_id]).destroy_all
      render json: {
        message: "Earned badges successfully deleted",
        success: true
        },
        status: 200
    else
      render json: {
        message: "Earned badges failed to delete",
        success: false
        },
        status: 400
    end
  end

  # DELETE grade/:grade_id/student/:student_id/badge/:badge_id/earned_badge/:id
  def delete_earned_badge
    grade_params = params.slice(:grade_id, :student_id, :badge_id)
    if EarnedBadge.exists?(grade_params)
      EarnedBadge.where(grade_params).destroy_all
      render json: { message: "Earned badge successfully deleted", success: true }, status: 200
    else
      render json: { message: "Earned badge failed to delete", success: false }, status: 400
    end
  end

  # POST /grades/:id/remove
  # This is the method used when faculty delete a grade
  # it preserves the predicted grade
  def remove
    @grade = Grade.find(params[:id])
    @grade.raw_score = nil
    @grade.status = nil
    @grade.feedback = nil
    @grade.feedback_read = false
    @grade.feedback_read_at = nil
    @grade.feedback_reviewed = false
    @grade.feedback_reviewed_at = nil
    @grade.instructor_modified = false
    @grade.graded_at = nil

    @grade.update_attributes(params[:grade])

    if @grade.save
      score_recalculator(@grade.student)
      redirect_to @grade.assignment,
        notice: "#{ @grade.student.name }'s #{ @grade.assignment.name } grade was successfully deleted."
    else
      redirect_to @grade.assignment, notice:  @grade.errors.full_messages, status: 400
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

  def safe_grade_possible_points(grade)
    grade.point_total rescue nil
  end

  def score_recalculator(student)
    ScoreRecalculatorJob.new(user_id: student.id,
                           course_id: current_course.id).enqueue
  end

  def rubric_criteria_with_levels
    @rubric_criteria_with_levels ||= @rubric.criteria.ordered.includes(:levels)
  end

  def set_assignment
    @assignment = Assignment.find(params[:assignment_id]) if params[:assignment_id]
  end
end
