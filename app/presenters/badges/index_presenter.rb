require "./lib/showtime"

class Badges::IndexPresenter < Showtime::Presenter
  include Showtime::ViewContext

  def badges
    properties[:badges]
  end

  def student
    properties[:student]
  end

  def title
    properties[:title]
  end

  def earned_badges_count(badge)
    if student
      student.visible_earned_badges_for_badge_count(badge)
    else
      badge.awarded_count
    end
  end

  # Method used to determine when the view context is
  # True:
  #  - a student viewing `/badges`
  #  - a faculty viewing `student/:student_id/badges`
  # False:
  #  - a faculty viewing `/badges`
  #
  def view_student_context?
    student.present?
  end
end
