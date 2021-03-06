require "./lib/showtime"

class Info::DashboardCoursePlannerPresenter < Showtime::Presenter
  include Showtime::ViewContext
  include Submissions::GradeHistory

  def course
    properties[:course]
  end

  def student
    properties[:student]
  end

  def assignments
    properties[:assignments]
  end

  def due_dates?
    assignments.any?{ |assignment| assignment.due_at? }
  end

  def grade_for(assignment)
    student.grade_for_assignment(assignment)
  end

  def to_do?(assignment)
    if student
      assignment.include_in_to_do? && assignment.visible_for_student?(student) && !GradeProctor.new(grade_for(assignment)).viewable?
    else
      assignment.include_in_to_do?
    end
  end

  def course_planner?(assignment)
    to_do?(assignment) && assignment.soon?
  end

  def course_planner_assignments
    assignments.select{ |assignment| course_planner?(assignment) }
  end

  def my_planner?(assignment)
    if due_dates?
      course_planner?(assignment) && starred?(assignment)
    else
      to_do?(assignment) && starred?(assignment)
    end
  end

  def my_planner_assignments
    assignments.select{ |assignment| my_planner?(assignment) }
  end

  def submittable?(assignment)
    assignment.accepts_submissions? && assignment.is_unlocked_for_student?(student)
  end

  def starred?(assignment)
    assignment.is_predicted_by_student?(student)
  end

  def submitted?(assignment)
    student.submission_for_assignment(assignment).present?
  end
end
