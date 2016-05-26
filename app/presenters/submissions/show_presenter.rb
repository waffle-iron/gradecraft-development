require_relative "../../models/history_filter"
require_relative "presenter"
require_relative "grade_history"

class Submissions::ShowPresenter < Submissions::Presenter
  include Submissions::GradeHistory

  def id
    properties[:id]
  end

  def grade
    if assignment.is_individual?
      assignment.grades.where(student_id: student.id).first
    else
      assignment.grades.where(group_id: group.id).first
    end
  end

  def submission
    assignment.submissions.find(id)
  end

  def submission_grade_history
    submission_grade_filtered_history(submission, grade, false)
  end

  def student
    submission.student
  end

  # override: params[:group_id] not available on show
  def group
    submission.group
  end

  def group_id
    submission.group.id
  end

  def open_for_editing?
    (assignment.open? && !grade.present?) ||
      (assignment.open? && assignment.resubmissions_allowed?)
  end

  def title
    if assignment.is_individual?
      name = student.first_name
    else
      name = group.name
    end
    "#{name}'s #{assignment.name} Submission (#{view_context.points assignment.point_total} #{"point".pluralize(assignment.point_total)})"
  end
end
