class ChallengeGrade < ActiveRecord::Base
  include GradeStatus

  belongs_to :course
  belongs_to :challenge
  belongs_to :team, autosave: true

  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_team, ->(team) { where(team_id: team.id) }

  validates_presence_of :team, :challenge

  delegate :name, :description, :due_at, :full_points, to: :challenge

  releasable_through :challenge

  validates :challenge_id, uniqueness: { scope: :team_id }
  validates_presence_of :team_id

  def score
    super.presence || nil
  end

  def cache_team_scores
    team.update_challenge_grade_score!
    team.update_average_score!
  end
end
