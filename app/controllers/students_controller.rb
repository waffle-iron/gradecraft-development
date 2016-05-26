class StudentsController < ApplicationController
  respond_to :html, :json

  before_filter :ensure_staff?,
    except: [:timeline, :predictor, :course_progress, :badges, :teams, :syllabus ]
  before_filter :save_referer, only: [:recalculate]

  # Lists all students in the course,
  # broken out by those being graded and auditors
  def index
    @title = "#{(current_course.user_term).singularize} Roster"

    @teams = current_course.teams

    if params[:team_id].present?
      @team = current_course.teams.find_by(id: params[:team_id])
      @students = current_course.students_being_graded_by_team(@team)
    else
      @students = current_course.students
    end
  end

  # Displays all students flagged by the current user
  def flagged
    @title = "Flagged #{(current_course.user_term).pluralize}"
    @students = FlaggedUser.flagged current_course, current_user
  end

  # Course wide leaderboard - excludes auditors from view
  def leaderboard
    render :leaderboard, Students::LeaderboardPresenter.build(course: current_course, team_id: params[:team_id])
  end

  # Students' primary page: displays all assignments and
  # team challenges in course
  def syllabus
    render :syllabus, Students::SyllabusPresenter.build({
      student: current_student,
      assignment_types: current_course.assignment_types.includes(:assignments),
      course: current_course,
      view_context: view_context
    })
  end

  # Course timeline, displays all assignments that are determined by the
  # instructor to belong on the timeline + team challenges if present
  def timeline
    if current_user_is_student?
      redirect_to dashboard_path
    end
    @events = Timeline.new(current_course).events
  end

  # Displaying student profile to instructors
  def show
    self.current_student = current_course.students.where(id: params[:id]).first
    @display_sidebar = true
    render :show, Students::SyllabusPresenter.build({
      student: self.current_student,
      assignment_types: current_course.assignment_types.includes(:assignments),
      course: current_course,
      view_context: view_context
    })
  end

  # AJAX endpoint for student name search
  def autocomplete_student_name
    students = current_course.students.map do |u|
      { name: [u.first_name, u.last_name].join(" "), id: u.id }
    end
    render json: MultiJson.dump(students)
  end

  # Displaying the course grading scheme and professor's grading philosophy
  def course_progress
    @grade_scheme_elements = current_course.grade_scheme_elements.order_by_high_range
    @title = "Your Course Progress"
    @display_sidebar = true
  end

  def teams
    @title = "#{term_for :teams}"
    @display_sidebar = true
    @team = current_student.team_for_course(current_course)
  end

  # Display the grade predictor
  #   students - style blocks to fill entire page, render layout with no sidebar
  #   staff - render standard layout with sidebar
  def predictor
    # id is used for api routes
    @student_id = current_student.id if current_student && current_user_is_staff?
    if current_user_is_student?
      @fullpage = true
      render layout: "predictor"
    end
  end

  # All Admins to see all of one student's grades at once, proof for duplicates
  def grade_index
    @grades = current_student.grades.where(course_id: current_course)
    @display_sidebar = true
  end

  def recalculate
    @student = current_course.students.find_by(id: params[:student_id])

    # @mz TODO: add specs
    ScoreRecalculatorJob.new(user_id: @student.id, course_id: current_course.id).enqueue

    flash[:notice]="Your request to recalculate #{@student.name}'s grade is being processed. Check back shortly!"
    redirect_to session[:return_to] || student_path(@student)
  end
end
