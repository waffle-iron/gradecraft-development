# Called from the assignments Controller, this assembles the assignments
# for a student with the student's grades nested within each assignment.
# Permission to update predictions is only granted if the user is the student.

class PredictedAssignmentCollectionSerializer
  include Enumerable

  attr_reader :assignments, :current_user, :student

  def initialize(assignments, current_user, student)
    @assignments = pluck_attributes assignments
    @current_user = current_user
    @student = student
  end

  def each
    assignments.each { |assignment| yield PredictedAssignmentSerializer.new(assignment, current_user, student) }
  end

  def [](index)
    to_a[index]
  end

  def permission_to_update?
    current_user == student
  end

  private

  def pluck_attributes(assignments)
    assignments.select(
      :accepts_submissions,
      :accepts_submissions_until,
      :assignment_type_id,
      :description,
      :due_at,
      :grade_scope,
      :id,
      :include_in_predictor,
      :name,
      :pass_fail,
      :point_total,
      :points_predictor_display,
      :position,
      :threshold_points,
      :required,
      :use_rubric,
      :visible,
      :visible_when_locked
    )
  end
end

