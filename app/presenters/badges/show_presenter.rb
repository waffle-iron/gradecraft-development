require "./lib/showtime"

class Badges::ShowPresenter < Showtime::Presenter
  include Showtime::ViewContext

  def course
    properties[:course]
  end

  def badge
    properties[:badge]
  end

  def student
    properties[:student]
  end

  def title
    badge.name
  end

  def teams
    properties[:teams]
  end

  def params
    properties[:params]
  end

  def team
    teams.find_by(id: params[:team_id]) if params[:team_id].present?
  end

  def students
    if team
      course.students_being_graded_by_team(team)
    else
      course.students_being_graded
    end
  end

  def earned_badges
    if student
      student.visible_earned_badges_for_badge(badge)
    else
      badge.earned_badges
    end
  end

  # Method used to determine when the view context is
  # True:
  #  - a student viewing `/badges/:id`
  #  - a faculty viewing `/students/:student_id/badges/:id`
  # False:
  #  - a faculty viewing `/badges/:id`
  #
  def view_student_context?
    student.present?
  end
end
