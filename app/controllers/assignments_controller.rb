class AssignmentsController < ApplicationController
  include AssignmentsHelper
  include SortsPosition

  before_filter :ensure_staff?, except: [:show, :index]

  def index
    redirect_to syllabus_path and return if current_user_is_student?
    @title = "#{term_for :assignments}"
    @assignment_types = current_course.assignment_types.includes(:assignments)
  end

  # Gives the instructor the chance to quickly check all assignment settings
  # for the whole course
  def settings
    @title = "Review #{term_for :assignment} Settings"
    @assignment_types = current_course.assignment_types.includes(:assignments)
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
    redirect_to assignment_path(duplicated), notice: "#{(term_for :assignment).titleize} #{duplicated.name} successfully created"
  end

  def create
    assignment = current_course.assignments.new(params[:assignment])
    if assignment.save
      set_assignment_weights(assignment)
      redirect_to assignment_path(assignment), notice: "#{(term_for :assignment).titleize} #{assignment.name} successfully created" and return
    end

    @title = "Create a New #{term_for :assignment}"
    render :new, Assignments::Presenter.build({
      assignment: assignment,
      course: current_course,
      view_context: view_context
      })
  end

  def update
    assignment = current_course.assignments.find(params[:id])
    if assignment.update_attributes(params[:assignment])
      set_assignment_weights(assignment)
      respond_to do |format|
        format.html {
          redirect_to assignments_path,
            notice: "#{(term_for :assignment).titleize} #{assignment.name } "\
            "successfully updated" and return
        }
        format.json { render json: assignment and return }
      end
    end

    respond_to do |format|
      format.html {
        @title = "Edit #{term_for :assignment}"
        render :edit, Assignments::Presenter.build({
          assignment: assignment,
          course: current_course,
          view_context: view_context
          })
      }
      format.json { render json: { errors: assignment.errors }, status: 400 }
    end
  end

  def sort
    sort_position_for :assignment
  end

  def destroy
    assignment = current_course.assignments.find(params[:id])
    assignment.destroy
    redirect_to assignments_url, notice: "#{(term_for :assignment).titleize} #{assignment.name} successfully deleted"
  end

  def export_structure
    respond_to do |format|
      format.csv { send_data AssignmentExporter.new.export current_course }
    end
  end

  private

  def set_assignment_weights(assignment)
    return unless assignment.student_weightable?
    assignment.weights = current_course.students.map do |student|
      assignment_weight =
        assignment.weights.where(student: student).first ||
          assignment.weights.new(student: student)
      assignment_weight.weight =
        assignment.assignment_type.weight_for_student(student)
      assignment_weight
    end
    assignment.save
  end
end
