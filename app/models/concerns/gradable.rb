module Gradable
  extend ActiveSupport::Concern

  included do
    attr_accessible :grades_attributes

    has_many :grades, dependent: :destroy
    has_many :predicted_earned_grades, dependent: :destroy

    accepts_nested_attributes_for :grades,
      reject_if: proc { |attrs| attrs[:raw_score].blank? }
  end

  def graded_or_released_scores
    grades.graded_or_released.pluck(:raw_score)
  end

  def grade_count
    grades.graded_or_released.count
  end

  # Getting a student's grade object for an assignment
  def grade_for_student(student)
    grades.graded_or_released.where(student_id: student.id).first
  end

  def average
    grades.graded_or_released.average(:raw_score).to_i \
      if grades.graded_or_released.present?
  end

  # Average of above-zero grades for an assignment
  def earned_average
    grades.graded_or_released.where("score > 0").average(:score).to_i
  end

  # Calculating how many of each score exists
  def earned_score_count
    grades.graded_or_released
      .group_by { |g| g.raw_score }
      .map { |score, grade| [score, grade.size ] }.to_h
  end

  def high_score
    grades.graded_or_released.maximum(:raw_score)
  end

  def low_score
    grades.graded_or_released.minimum(:raw_score)
  end

  def is_predicted_by_student?(student)
    grade = predicted_earned_grades.where(student_id: student.id).first
    !grade.nil? && grade.predicted_points > 0
  end

  def median
    sorted = grades.graded_or_released.not_nil.pluck(:score).sort
    return 0 if sorted.empty?
    (sorted[(sorted.length - 1) / 2] + sorted[sorted.length / 2]) / 2
  end

  def predicted_count
    predicted_earned_grades.predicted_to_be_done.count
  end
end
