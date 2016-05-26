class Team < ActiveRecord::Base
  attr_accessible :name, :course, :course_id, :student_ids, :score, :students,
    :leaders, :teams_leaderboard, :in_team_leaderboard, :banner, :rank,
    :leader_ids

  validates_presence_of :course, :name
  validates :name, uniqueness: { case_sensitive: false, scope: :course_id }

  # TODO: remove these callbacks
  before_save :cache_score

  # Teams belong to a single course
  belongs_to :course, touch: true

  has_many :team_memberships
  has_many :students, through: :team_memberships, autosave: true
  has_many :team_leaderships
  has_many :leaders, through: :team_leaderships

  # Teams design banners that they display on the leadboard
  mount_uploader :banner, ImageUploader

  # Teams don't currently earn badges directly - but they are recognized for
  # the badges their students earn
  has_many :earned_badges, through: :students

  # Teams compete through challenges, which earn points through challenge_grades
  has_many :challenge_grades
  has_many :challenges, through: :challenge_grades

  accepts_nested_attributes_for :team_memberships

  # Various ways to sort the display of teams
  scope :order_by_high_score, -> { order "teams.score DESC" }
  scope :order_by_low_score, -> { order "teams.score ASC" }
  scope :order_by_average_high_score, -> { order "average_points DESC"}
  scope :alpha, -> { order "teams.name ASC"}

  def self.find_by_course_and_name(course_id, name)
    where(course_id: course_id)
      .where("LOWER(name) = :name", name: name.downcase).first
  end

  # @mz TODO: add specs
  def recalculate_student_scores
    student_score_recalculator_jobs.each(&:enqueue)
  end

  # @mz TODO: add specs
  def student_score_recalculator_jobs
    @student_score_recalculator_jobs ||= students.collect do |student|
      ScoreRecalculatorJob.new(user_id: student.id, course_id: course_id)
    end
  end

  # Tallying how many students are on the team
  def member_count
    students.count
  end

  # Tallying how many badges the students on the team have earned total
  def badge_count
    earned_badges.where(course_id: self.course_id).student_visible.count
  end

  def total_earned_points
    total_score = 0
    students.each do |student|
      total_score += (student.cached_score_for_course(course) || 0 )
    end
    return total_score
  end

  # Calculating the average points amongst all students on the team
  def average_points
    if member_count > 0
      average_points = total_earned_points / member_count
    else
      return 0
    end
  end

  def update_ranks
    @teams = self.course.teams
    rank_index = @teams.pluck(:score).uniq.sort.reverse

    @teams.each do |team|
      rank = rank_index.index(team.score) + 1
      team.update_attributes rank: rank
    end
  end

  # Summing all of the points the team has earned across their challenges
  def challenge_grade_score
    # use student_visible scope from challenge_grades
    challenge_grades.student_visible.sum("score") || 0
  end

  # Teams rack up points in two ways, which is used is determined by the
  # instructor in the course settings.
  # The first way is that the team's score is the average of its students'
  # scores, and challenge grades are added directly into students' scores.
  # The second way is that the teams compete in team challenges that earn
  # the team points. At the end of the semester these usually get added back
  # into students' scores - this has not yet been built into GC.
  def cache_score
    if course.team_score_average
      self.score = average_points
    else
      self.score = challenge_grade_score
    end
  end

  def update_revised_team_score
    update_attributes score: revised_team_score
  end

  private

  def revised_team_score
    course.team_score_average ? average_points : challenge_grade_score
  end
end
