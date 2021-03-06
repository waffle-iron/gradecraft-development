class StudentsController < ApplicationController
  respond_to :html, :json

  before_action :ensure_staff?
  before_action :save_referer, only: [:recalculate]

  # Lists all students in the course,
  # broken out by those being graded and auditors
  def index
    render "index", Students::IndexPresenter.build(course: current_course, team_id: params[:team_id])
  end

  # Displaying student profile to instructors
  def show
    @events = Timeline.new(current_course).events_by_due_date
    self.current_student = current_course.students.where(id: params[:id]).first
    render "show", Info::DashboardCoursePlannerPresenter.build({
      student: current_student,
      assignments: current_course.assignments.chronological.includes(:assignment_type, :unlock_conditions),
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

  # All Admins to see all of one student's grades at once, proof for duplicates
  def grade_index
    student = current_course.students.find_by(id: params[:id])
    @grades = student.grades.where(course_id: current_course)
  end

  def recalculate
    @student = current_course.students.find_by(id: params[:id])

    # @mz TODO: add specs
    ScoreRecalculatorJob.new(user_id: @student.id,
      course_id: current_course.id).enqueue

    flash[:notice]="Your request to recalculate #{@student.name}'s grade is being processed. Check back shortly!"
    redirect_to session[:return_to] || student_path(@student)
  end
end
