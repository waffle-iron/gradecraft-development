require "active_support/inflector"
require "./lib/showtime"
require_relative "../submissions/grade_history"
require_relative "../../models/history_filter"

class Assignments::Presenter < Showtime::Presenter
  include Showtime::ViewContext
  include Submissions::GradeHistory

  def assignment
    properties[:assignment]
  end

  def assignment_type
    assignment.assignment_type
  end

  def completion_rate
    assignment.completion_rate(course)
  end

  def course
    properties[:course]
  end

  def for_team?
    properties.key?(:team_id) && !team.nil?
  end

  def grade_for(student)
    grades.where(student_id: student.id).first ||
      Grade.new(assignment_id: assignment.id)
  end

  def grades
    assignment.grades
  end

  def grades_available_for?(user)
    user.grade_released_for_assignment?(assignment)
  end

  def groups
    Assignments::GroupPresenter.wrap(assignment.groups, :group, { assignment: assignment })
  end

  def group_assignment?
    assignment.has_groups?
  end

  def group_for(student)
    student.group_for_assignment(assignment)
  end

  def group_submission_for(student)
    group_for(student).submission_for_assignment(assignment)
  end

  def has_grades?
    grades.present?
  end

  def has_reviewable_grades?
    grades.instructor_modified.present?
  end

  def has_submission_for?(user)
    assignment.accepts_submissions? && !user.submission_for_assignment(assignment).nil?
  end

  def has_teams?
    course.has_teams?
  end

  def assignment_has_viewible_description?(user)
    assignment.description.present? &&
    ( user.is_staff?(course) ||
      assignment.description_visible_for_student?(user)
    )
  end

  def assignment_has_viewible_purpose?(user)
    assignment.purpose.present? &&
    ( user.is_staff?(course) ||
      assignment.purpose_visible_for_student?(user)
    )
  end

  def assignment_accepting_submissions?(student)
    student.present? &&
    assignment.accepts_submissions? &&
    ( assignment.is_unlocked_for_student?(student) ||
      ( assignment.has_groups? &&
        assignment.is_unlocked_for_group?(
          student.group_for_assignment(assignment))
      )
    )
  end

  def hide_analytics?
    course.hide_analytics? && assignment.hide_analytics?
  end

  def individual_assignment?
    assignment.is_individual?
  end

  def submission_submitted_date_for(submissions)
    submission = submissions.first
    submission.submitted_at if submission
  end

  def submission_resubmitted?(submissions)
    submission = submissions.first
    submission.nil? ? false : submission.resubmitted?
  end

  def new_assignment?
    !assignment.persisted?
  end

  def rubric
    assignment.fetch_or_create_rubric
  end

  def grade_with_rubric?
    assignment.grade_with_rubric?
  end

  # show the rubric preview tab on student's view
  def show_rubric_preview?(user)
    grade_with_rubric? && !grades_available_for?(user) && ( !user || assignment.description_visible_for_student?(user) )
  end

  def scores
    { scores: assignment.graded_or_released_scores }
  end

  def scores_for(user)
    scores = self.scores
    grade = grades.where(student_id: user.id).first
    if GradeProctor.new(grade).viewable? user: user, course: course
      scores[:user_score] = grade.raw_score
    end
    scores
  end

  def has_scores_for?(user)
    scores = scores_for(user)
    !scores.nil? && !scores.empty? && scores.key?(:scores) && !scores[:scores].empty?
  end

  def student_logged?(user)
    assignment.student_logged? && assignment.open? && user.is_student?(course)
  end

  def students
    for_team? ? course.students_by_team(team) : course.students
  end

  def students_being_graded
    for_team? ? course.students_being_graded_by_team(team) : course.students_being_graded
  end

  def submission_for_assignment(student)
    student.submission_for_assignment(assignment)
  end

  def submissions_for(student)
    student.submissions.where(assignment_id: assignment.id) || Submission.none
  end

  def submission_rate
    assignment.submission_rate(course)
  end

  def submission_grade_history(student)
    grade = self.grade_for(student)
    submission = self.submission_for_assignment(student)
    submission_grade_filtered_history(submission, grade)
  end

  def title
    title = assignment.name
  end

  def team
    @team ||= teams.find_by(id: properties[:team_id])
  end

  def teams
    course.teams
  end
end
