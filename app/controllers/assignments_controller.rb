require "canvas"

class AssignmentsController < ApplicationController
  include AssignmentsHelper
  include SortsPosition

  before_filter :ensure_staff?, except: [:show, :index]
  before_filter :sanitize_params, only: [:create, :update]

  def index
    @title = "#{term_for :assignments}"
    @assignment_types = current_course.assignment_types.ordered.includes(:assignments)
    if current_user_is_student?
      render :index, Assignments::StudentPresenter.build({
        student: current_student,
        assignment_types: current_course.assignment_types.includes(:assignments),
        course: current_course,
        view_context: view_context
      })
    end
  end

  # Gives the instructor the chance to quickly check all assignment settings
  # for the whole course
  def settings
    @title = "Review #{term_for :assignment} Settings"
    @assignment_types = current_course.assignment_types.ordered.includes(:assignments)
  end

  def show
    assignment = current_course.assignments.find_by(id: params[:id])
    redirect_to assignments_path,
      alert: "The #{(term_for :assignment)} could not be found." and return unless assignment.present?

    mark_assignment_reviewed! assignment, current_user
    render :show, Assignments::Presenter.build({
      assignment: assignment,
      course: current_course,
      team_id: params[:team_id],
      view_context: view_context
      })
  end

  def new
    render :new, Assignments::Presenter.build({
      assignment: current_course.assignments.new,
      course: current_course,
      view_context: view_context
      })
  end

  def edit
    assignment = current_course.assignments.find(params[:id])
    @title = "Editing #{assignment.name}"
    render :edit, Assignments::Presenter.build({
      assignment: assignment,
      course: current_course,
      view_context: view_context
      })
  end

  # Duplicate an assignment - important for super repetitive items like
  # attendance and reading reactions
  def copy
    assignment = current_course.assignments.find(params[:id])
    duplicated = assignment.copy
    redirect_to edit_assignment_path(duplicated)
    flash[:success] = "#{(term_for :assignment).titleize} #{duplicated.name} successfully created"
  end

  def create
    assignment = current_course.assignments.new(assignment_params)
    if assignment.save
<<<<<<< 748e543780793688994cf2eaa8ae06af1a10d364
      redirect_to assignments_path,
        notice: "#{(term_for :assignment).titleize} #{assignment.name} successfully created" \
        and return
=======
      flash[:success] = "#{(term_for :assignment).titleize} #{assignment.name} successfully created"
      redirect_to assignment_path(assignment)
    else 
      @title = "Create a New #{term_for :assignment}"
      render :new, Assignments::Presenter.build({
        assignment: assignment,
        course: current_course,
        view_context: view_context
        })
>>>>>>> Assignment Types Controller cleanup
    end
  end

  def update
    assignment = current_course.assignments.find(params[:id])
    if assignment.update_attributes assignment_params
      flash[:success] = "#{(term_for :assignment).titleize} #{assignment.name } successfully updated"
      redirect_to assignments_path
    else 
      @title = "Edit #{term_for :assignment}"
      render :edit, Assignments::Presenter.build({
        assignment: assignment,
        course: current_course,
        view_context: view_context
        })
    end
  end

  def sort
    sort_position_for :assignment
  end

  def destroy
    assignment = current_course.assignments.find(params[:id])
    assignment.destroy
    redirect_to assignments_url
    flash[:success] = "#{(term_for :assignment).titleize} #{assignment.name} successfully deleted"
  end

  def export_structure
    course = current_user.courses.find_by(id: params[:id])
    respond_to do |format|
      format.csv { send_data AssignmentExporter.new.export(course), filename: "#{ course.name } #{ (term_for :assignment).titleize } Structure - #{ Date.today }.csv" }
    end
  end

  private

  def sanitize_params
    [:full_points, :threshold_points].each do |points|
      if params[:assignment][points].class == String
        params[:assignment][points].delete!(",").to_i
      end
    end
  end

  def assignment_params
    params.require(:assignment).permit :accepts_attachments, :accepts_links,
      :accepts_submissions, :accepts_submissions_until, :accepts_resubmissions_until,
      :accepts_text, :assignment_file, :assignment_file_ids, :assignment_score_level,
      :assignment_type_id, :course_id, :description, :due_at, :grade_scope,
      :include_in_predictor, :include_in_timeline, :include_in_to_do,
      :mass_grade_type, :name, :open_at, :pass_fail, :max_submissions,
      :full_points, :purpose, :release_necessary, :hide_analytics,
      :required, :resubmissions_allowed, :show_description_when_locked,
      :show_purpose_when_locked, :show_name_when_locked,
      :show_points_when_locked, :student_logged, :threshold_points, :use_rubric,
      :visible, :visible_when_locked, :min_group_size, :max_group_size,
      unlock_conditions_attributes: [:id, :unlockable_id, :unlockable_type, :condition_id,
        :condition_type, :condition_state, :condition_value, :condition_date, :_destroy],
      assignment_files_attributes: [:id, file: []],
      assignment_score_levels_attributes: [:id, :name, :points, :_destroy],
      assignment_groups_attributes: [:group_id]
  end
end
