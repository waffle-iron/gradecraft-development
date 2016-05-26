require "./lib/showtime"

class Submissions::Presenter < Showtime::Presenter
  include Showtime::ViewContext

  def assignment
    course.assignments.find assignment_id
  end

  def assignment_id
    properties[:assignment_id]
  end

  def course
    properties[:course]
  end

  def group
    course.groups.find(group_id) if assignment.has_groups?
  end

  def group_id
    properties[:group_id]
  end
end
