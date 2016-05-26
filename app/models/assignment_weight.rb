class AssignmentWeight < ActiveRecord::Base
  attr_accessible :student, :student_id, :assignment, :assignment_id, :weight

  belongs_to :student, class_name: "User", touch: true
  belongs_to :assignment_type
  belongs_to :assignment, touch: true
  belongs_to :course
  belongs_to :submission

  before_validation :cache_associations, :cache_point_total

  validates_presence_of :student, :assignment, :assignment_type, :course, :weight

  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }

  private

  def cache_associations
    self.assignment_type_id ||= assignment.try(:assignment_type_id)
    self.course_id ||= assignment.try(:course_id)
  end

  def cache_point_total
    self.point_total = assignment.point_total_for_student(student, weight)
  end

end
