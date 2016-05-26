class PredictedEarnedGrade < ActiveRecord::Base

  attr_accessible :student_id, :assignment_id, :predicted_points

  belongs_to :assignment
  belongs_to :student, class_name: "User"

  scope :predicted_to_be_done, -> { where("predicted_points > 0")}
  scope :for_course, ->(course) do
    joins(:assignments).where(assignments: {course_id: course.id})
  end
  scope :for_student, ->(student) { where(student_id: student.id) }

  validates :assignment_id, uniqueness: { scope: :student_id }
end
