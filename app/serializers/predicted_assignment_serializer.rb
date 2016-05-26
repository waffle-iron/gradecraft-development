# Called from the PredictedAssignmentCollectionSerializer, this class manages
# the presentation of an Assignment for the Predictor Page with the grade for
# a student nested within.

class PredictedAssignmentSerializer < SimpleDelegator
  attr_reader :current_user, :student

  def initialize(assignment, current_user, student)
    @assignment = assignment
    @current_user = current_user
    @student = student
    super assignment
  end

  def grade
    if @grade.nil?
      if student.present?
        grade = Grade.find_or_create(assignment.id, student.id)
      else
        grade = NullGrade.new
      end
      @grade = PredictedGradeSerializer.new(assignment, grade, current_user)
    end
    @grade
  end

  def prediction
    if @prediction.nil?
      if student.present?
        @prediction = PredictedEarnedGrade.find_or_create_by(
          assignment_id: assignment.id,
          student_id: student.id
        )
      else
        @prediction = NullPredictedEarnedGrade.new
      end
    end
    {
      id: @prediction.id,
      predicted_points: visible_predicted_points(@prediction.predicted_points)
    }
  end

  def attributes
    select_attributes.merge boolean_flags
  end

  def predictor_display_type
    assignment.predictor_display_type
  end

  def score_levels
    assignment.assignment_score_levels.map do |asl|
      {name: asl.name, value: asl.value}
    end
  end

  def unlock_conditions
    assignment.unlock_conditions.map do |condition|
      "#{condition.name} must be #{condition.condition_state}"
    end
  end

  def unlock_keys
    assignment.unlock_keys.map do |key|
      "#{key.unlockable.name} is unlocked by #{key.condition_state} #{key.condition.name}"
    end
  end

  private

  attr_reader :assignment

  def visible_predicted_points(points)
    @student == @current_user ? points : 0
  end

  # Selected attributes necessary for all method calls are declared in
  # predicted_assignment_collection_serializer. Here we further refine down to
  # only the attributes that will be passed to the front end.
  def select_attributes
    assignment.attributes.select do |attr,v|
      %w( accepts_submissions_until
          assignment_type_id
          description
          due_at
          id
          name
          pass_fail
          point_total
          position
          threshold_points
        ).include?(attr)
    end
  end

  # boolean states for icons in predictor
  def boolean_flags
    {
      accepting_submissions: accepting_submissions?,
      closed_without_submission: closed_without_sumbission?,
      has_been_unlocked: has_been_unlocked?,
      has_info: has_info?,
      is_rubric_graded: is_rubric_graded?,
      has_submission: has_submission?,
      has_threshold: has_threshold?,
      is_a_condition: is_a_condition?,
      is_earned_by_group: is_earned_by_group?,
      is_late: is_late?,
      is_locked: is_locked?,
      is_required: is_required?,
    }
  end

  def is_required?
    !!assignment.required
  end

  def has_info?
    !assignment.description.blank?
  end

  def is_rubric_graded?
    assignment.grade_with_rubric?
  end

  def is_earned_by_group?
    assignment.grade_scope == "Group"
  end

  def is_late?
    assignment.overdue? && assignment.accepts_submissions && \
      !student.submission_for_assignment(assignment).present?
  end

  def accepting_submissions?
    !!assignment.accepts_submissions? && \
    !assignment.submissions_have_closed? && \
    !student.submission_for_assignment(assignment).present?
  end

  def has_submission?
    !!assignment.accepts_submissions? && \
      student.submission_for_assignment(assignment).present?
  end

  def has_threshold?
    assignment.threshold_points && assignment.threshold_points > 0
  end

  def closed_without_sumbission?
    assignment.submissions_have_closed? && \
     !student.submission_for_assignment(assignment).present?
  end

  def is_locked?
    !assignment.is_unlocked_for_student?(student)
  end

  def has_been_unlocked?
    assignment.is_unlockable? && assignment.is_unlocked_for_student?(student)
  end

  def is_a_condition?
    assignment.is_a_condition?
  end
end
