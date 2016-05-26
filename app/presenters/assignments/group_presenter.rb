require "./lib/showtime"

class Assignments::GroupPresenter < Showtime::Presenter
  def assignment
    properties[:assignment]
  end

  def assignment_graded?
    grade = group.students.first.grade_for_assignment(assignment)
    !grade.nil? && grade.is_graded?
  end

  def grade_for(student)
    assignment.grades.find_by(student_id: student.id) || assignment.grades.build
  end

  def group
    properties[:group]
  end

  def has_submission?
    !submission.nil?
  end

  def submission
    @submission ||= group.submission_for_assignment(assignment)
  end

  def students
    group.students
  end

  def title
    "#{group.name} Grades"
  end
end
