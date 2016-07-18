require "./lib/showtime"

class Students::DashboardCourseRulesPresenter < Showtime::Presenter
  include Showtime::ViewContext

  def course
    properties[:course]
  end

  def term_for_assignments?
    course.assignment_term != "Assignment"
  end
end