class AssignmentTypesController < ApplicationController
  include SortsPosition

  before_filter :ensure_staff?
  before_action :find_assignment_type,
    only: [:show, :edit, :update, :export_scores, :all_grades, :destroy]

  # Display list of assignment types
  def index
    @title = "#{term_for :assignment_type} Analytics"
    @assignment_types =
      current_course.assignment_types.ordered.includes(assignments: :assignment_type)
    @students = current_course.students
  end

  # Create a new assignment type
  def new
    @title = "Create a New #{term_for :assignment_type}"
    @assignment_type = current_course.assignment_types.new
  end

  # Edit assignment type
  def edit
    @title = "Editing #{@assignment_type.name}"
  end

  # Create a new assignment type
  def create
    @assignment_type =
      current_course.assignment_types.new(assignment_type_params)
    @title = "Create a New #{term_for :assignment_type}"

    if @assignment_type.save
      flash[:success] = "#{(term_for :assignment_type).titleize} #{@assignment_type.name} successfully created"
      redirect_to assignments_path
    else
      render action: "new"
    end
  end

  # Update assignment type
  def update
    @title = "Editing #{@assignment_type.name}"
    @assignment_type.update_attributes(assignment_type_params)
    
    if @assignment_type.save
      flash[:success] = "#{(term_for :assignment_type).titleize} #{@assignment_type.name} successfully updated"
      redirect_to assignments_path
    else
      render action: "edit"
    end
  end 

  def sort
    sort_position_for "assignment-type"
  end

  def export_scores
    course = current_user.courses.find_by(id: params[:course_id])
    respond_to do |format|
      format.csv do
        send_data AssignmentTypeExporter.new.export_scores(@assignment_type, course, course.students),
        filename: "#{ course.name } #{ (term_for :assignment_type).titleize } Scores - #{ Date.today }.csv"
      end
    end
  end

  def export_all_scores
    course = current_user.courses.find_by(id: params[:id])
    if course.assignment_types.present?
      respond_to do |format|
        format.csv do
          send_data AssignmentTypeExporter.new.export_summary_scores(course.assignment_types,
            course, course.students),
          filename: "#{ course.name } #{ (term_for :assignment_type).titleize } Summary - #{ Date.today }.csv"
        end
      end
    else
      flash[:error] = "Sorry! You have not yet created an #{(term_for :assignment_type).titleize} for this course"
      redirect_to dashboard_path
    end
  end

  # display all grades for all assignments in an assignment type
  def all_grades
    @title = "#{@assignment_type.name} Grade Patterns"

    @teams = current_course.teams

    if params[:team_id].present?
      @team = @teams.find_by(id: params[:team_id])
      students = current_course.students_by_team(@team)
    else
      students = current_course.students
    end
    @students = students
  end

  # delete the specified assignment type
  def destroy
    @name = "#{@assignment_type.name}"
    @assignment_type.destroy
    redirect_to assignments_path
    flash[:success] = "#{(term_for :assignment_type).titleize} #{@name} successfully deleted"
  end

  private

  def assignment_type_params
    params.require(:assignment_type).permit(:max_points, :name, :description, :student_weightable,
                                            :position, :top_grades_counted)
  end

  def find_assignment_type
    @assignment_type = current_course.assignment_types.find(params[:id])
  end
end
