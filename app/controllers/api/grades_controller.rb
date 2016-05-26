class API::GradesController < ApplicationController

  before_filter :ensure_staff?

  # GET api/assignments/:assignment_id/students/:student_id/grade
  def show
    @grade = Grade.find_or_create(params[:assignment_id], params[:student_id])
    if @grade.assignment.release_necessary?
      @grade_status_options = Grade::STATUSES
    else
      @grade_status_options = Grade::UNRELEASED_STATUSES
    end
  end

  # POST api/grades/:grade_id
  def update
    grade = Grade.find(params[:id])
    grade.assign_attributes(grade_params)
    grade.instructor_modified = true
    if grade.raw_score_changed?
      grade.graded_at = DateTime.now
    end
    changes = grade.changes
    if grade.save
      grade.squish_history!
      render json: { message: {changes: changes}, success: true }
    else
      render json: {
        message: "failed to save grade", success: false
        },
        status: 500
    end
  end

  # GET api/assignments/:assignment_id/groups/:group_id/grades
  def group_index
    assignment = Assignment.find(params[:assignment_id])
    if !assignment.has_groups?
      render json: {
        message: "not a group assignment", success: false
        },
        status: 400
    else
      students = Group.find(params[:group_id]).students
      @student_ids = students.pluck(:id)
      @grades =
        Grade.find_or_create_grades(params[:assignment_id], @student_ids)
      if assignment.release_necessary?
        @grade_status_options = Grade::STATUSES
      else
        @grade_status_options = Grade::UNRELEASED_STATUSES
      end
    end
  end

  private

  def grade_params
    params.require(:grade).permit(:raw_score, :feedback, :status)
  end
end
