# Called from the PredictedAssignmentSerializer, this class manages the
# presentation of a student's grade for an Assignment on the Predictor Page.
#
# PERMISSIONS:
#  * Students CAN ONLY see released grades
#  * Faculty CAN NOT view student predictions

class PredictedGradeSerializer
  attr_reader :current_user

  def initialize(assignment, grade, current_user)
    @assignment = assignment
    @grade = grade
    @current_user = current_user
  end

  def attributes
    {
      id: id,
      score: score,
      final_points: final_points,
      is_excluded: excluded?
    }
  end

  def pass_fail_status
    grade.pass_fail_status if GradeProctor.new(grade).viewable?
  end

  private

  def id
    grade.id
  end

  def final_points
    return 0 if show_zero_in_predictor grade.final_points
    grade.final_points if GradeProctor.new(grade).viewable?
  end

  def score
    return 0 if show_zero_in_predictor grade.score
    grade.score if GradeProctor.new(grade).viewable?
  end

  def excluded?
    grade.excluded_from_course_score?
  end

  def show_zero_in_predictor(score)
    score.nil? &&
    assignment.accepts_submissions? &&
    assignment.submissions_have_closed? &&
    grade.student.submission_for_assignment(grade.assignment).nil?
  end

  attr_reader :assignment, :grade
end

