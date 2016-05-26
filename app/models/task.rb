class Task < ActiveRecord::Base
  attr_accessible :assignment, :assignment_id, :assignment_type, :name,
    :description, :due_at, :course_id

  belongs_to :assignment
  belongs_to :course
  has_many :submissions, dependent: :destroy

  before_validation :set_course

  private

  def set_course
    self.course_id = assignment.try(:course_id)
  end
end
