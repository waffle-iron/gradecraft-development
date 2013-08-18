class Team < ActiveRecord::Base
  attr_accessible :name, :course, :course_id, :student_ids, :score, :students

  belongs_to :course

  has_many :team_memberships
  has_many :students, :through => :team_memberships

  has_many :earned_badges, :as => :group

  has_many :challenge_grades
  has_many :challenges, :through => :challenge_grades

  after_validation :cache_score

  validates_presence_of :course, :name

  accepts_nested_attributes_for :team_memberships

  def team_leader
    students.gsis.first
  end

  def member_count
    students.count
  end

  def average_grade
    total_score = 0
    students.each do |student|
      total_score += student.score_for_course(course)
    end
    if member_count > 0
      average_grade = total_score / member_count
    end
  end

  private
  def cache_score
    self.score = challenge_grades.pluck('score').sum
  end
end