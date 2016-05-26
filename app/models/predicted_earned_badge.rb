class PredictedEarnedBadge < ActiveRecord::Base

  attr_accessible :student_id, :badge_id, :predicted_times_earned

  belongs_to :badge
  belongs_to :student, class_name: "User"

  scope :for_course, ->(course) do
    joins(:badge).where(badges: {course_id: course.id})
  end
  scope :for_student, ->(student) { where(student_id: student.id) }

  validates :badge_id, uniqueness: { scope: :student_id }

  def total_predicted_points
    self.badge.point_total * predicted_times_earned
  end

  def actual_times_earned
    self.badge.earned_badge_count_for_student(self.student)
  end

  # Returns the higher number: predicted times earned or actually earned and
  # visible to student
  def times_earned_including_actual
    if predicted_times_earned < actual_times_earned
      actual_times_earned
    else
      predicted_times_earned
    end
  end
end
