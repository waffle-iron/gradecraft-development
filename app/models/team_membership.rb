# @mz TODO: add course_id attribute to team_memberships
class TeamMembership < ActiveRecord::Base
  attr_accessible :team, :team_id, :student, :student_id

  belongs_to :team
  belongs_to :student, class_name: "User"

  validates_presence_of :team, :student

  scope :for_course, ->(course) do
    joins(:team).where(teams: {course_id: course.id})
  end

  scope :for_student, ->(student) { where(student_id: student.id) }

end
