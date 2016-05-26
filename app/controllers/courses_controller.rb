class CoursesController < ApplicationController
  include CoursesHelper

  before_filter :ensure_staff?, except: [:timeline]

  def index
    @title = "Course Index"
    @courses = current_user.courses
    # Used to return the course list to search
    respond_to do |format|
      format.html { }
      format.json { render json: @courses.to_json(only: [:id, :name, :courseno,
                                                         :year, :semester])
                                                       }
    end
  end

  def show
    @title = "Course Settings"
    @course = Course.find(params[:id])
  end

  def new
    @title = "Create a New Course"
    @course = Course.new
  end

  def edit
    @title = "Editing Basic Settings"
    @course = Course.find(params[:id])
  end

  def copy
    course = Course.find(params[:id])
    duplicated = course.copy
    if duplicated.save
      if !current_user_is_admin?
        duplicated.course_memberships.create(user: current_user, role: current_role)
      end
      session[:course_id] = duplicated.id
      redirect_to course_path(duplicated.id),
        notice: "#{course.name} successfully copied"
    else
      redirect_to courses_path,
        alert: "#{course.name} was not successfully copied"
    end
  end

  def create
    @course = Course.new(params[:course])
    @title = "Create a New Course"

    respond_to do |format|
      if @course.save
        if !current_user_is_admin?
          @course.course_memberships.create(user_id: current_user.id,
                                            role: current_user.role(current_course))
        end
        session[:course_id] = @course.id
        bust_course_list_cache current_user
        format.html {
          redirect_to course_path(@course),
          notice: "Course #{@course.name} successfully created"
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    @course = Course.find(params[:id])
    @title = "Editing Basic Settings"

    respond_to do |format|
      if @course.update_attributes(params[:course])
        bust_course_list_cache current_user
        format.html {
          redirect_to @course,
          notice: "Course #{@course.name} successfully updated"
        }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def timeline_settings
    @course = current_course
    @assignments = @course.assignments.includes(:assignment_type)
    @title = "Timeline Settings"
  end

  def timeline_settings_update
    @course = current_course
    if @course.update_attributes(params[:course])
      redirect_to dashboard_path
    else
      render action: "timeline_settings", course: @course
    end
  end

  def predictor_settings
    @course = current_course
    @assignments = current_course.assignments.includes(:assignment_type)
    @title = "Grade Predictor Settings"
  end

  def predictor_settings_update
    @course = current_course
    if @course.update_attributes(params[:course])
      respond_with @course
    else
      render action: "predictor_settings", course: @course
    end
  end

  def destroy
    @course = Course.find(params[:id])
    @name = @course.name
    @course.destroy

    respond_to do |format|
      format.html {
        redirect_to courses_url,
        notice: "Course #{@name} successfully deleted"
      }
    end
  end

  def export_earned_badges
    course = current_course
    respond_to do |format|
      format.csv {
        send_data EarnedBadgeExporter.new.earned_badges_for_course course.earned_badges
      }
    end
  end
end
