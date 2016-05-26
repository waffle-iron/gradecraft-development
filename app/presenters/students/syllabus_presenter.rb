require "./lib/showtime"

class Students::SyllabusPresenter < Showtime::Presenter
  include Showtime::ViewContext

  def course
    properties[:course]
  end

  def student
    properties[:student]
  end

  def assignment_types
    properties[:assignment_types]
  end

  def assignments_for(assignment_type)
    assignment_type.assignments.includes(:assignment_type, :unlock_conditions)
  end

  def assignment_visible?(assignment)
    assignment.visible_for_student?(student) ||
      GradeProctor.new(grade_for(assignment)).viewable?
  end

  def name_visible?(assignment)
    assignment.name_visible_for_student?(student) ||
      GradeProctor.new(grade_for(assignment)).viewable?
  end

  def points_visible?(assignment)
    assignment.points_visible_for_student?(student) ||
      GradeProctor.new(grade_for(assignment)).viewable?
  end

  def grade_for(assignment)
    student.grade_for_assignment(assignment)
  end

  def group_for(assignment)
    student.group_for_assignment(assignment)
  end

  def submission_for(assignment)
    student.submission_for_assignment(assignment)
  end

  def open?(assignment)
    assignment.student_logged? && assignment.open?
  end

  def locked?(assignment)
    assignment.is_unlockable? && !assignment.is_unlocked_for_student?(student)
  end

  def submittable?(assignment)
    assignment.accepts_submissions? &&
        assignment.is_unlocked_for_student?(student)
  end
end
