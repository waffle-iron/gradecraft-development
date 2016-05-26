class AssignmentTypesController < ApplicationController
  include SortsPosition

  before_filter :ensure_staff?, except: [:predictor_data]
  before_action :find_assignment_type,
    only: [:show, :edit, :update, :export_scores, :all_grades, :destroy]

  # Display list of assignment types
  def index
    @title = "#{term_for :assignment_types}"
    @assignment_types =
      current_course.assignment_types.includes(assignments: :assignment_type)
    @students = current_course.students
  end

  # See assignment type with all of its included assignments
  def show
    @title = "#{@assignment_type.name}"
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
      current_course.assignment_types.new(params[:assignment_type])
    @title = "Create a New #{term_for :assignment_type}"

    respond_to do |format|
      if @assignment_type.save
        format.html { redirect_to @assignment_type, flash: {
          success: "#{(term_for :assignment_type).titleize} #{@assignment_type.name} successfully created" }
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  # Update assignment type
  def update
    @title = "Editing #{@assignment_type.name}"
    @assignment_type.update_attributes(params[:assignment_type])

    respond_to do |format|
      if @assignment_type.save
        format.html { redirect_to assignment_types_path, flash: {
          success: "#{(term_for :assignment_type).titleize} #{@assignment_type.name} successfully updated" }
        }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def sort
    sort_position_for "assignment-type"
  end

  def export_scores
    respond_to do |format|
      format.csv {
        send_data AssignmentTypeExporter.new.export_scores @assignment_type,
          current_course, current_course.students
        }
    end
  end

  def export_all_scores
    if current_course.assignment_types.present?
      respond_to do |format|
        format.csv {
          send_data AssignmentTypeExporter.new.export_summary_scores current_course.assignment_types,
            current_course, current_course.students
        }

        flash[:success]=
          "Your assignment type summary file has been successfully downloaded"
      end
    else
      redirect_to dashboard_path, flash: {
        error: "Sorry! You have not yet created an #{(term_for :assignment_type).titleize} for this course"
      }
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
    redirect_to assignment_types_path, flash: {
      success: "#{(term_for :assignment_type).titleize} #{@name} successfully deleted"
    }
  end

  private

  def find_assignment_type
    @assignment_type = current_course.assignment_types.find(params[:id])
  end
end
