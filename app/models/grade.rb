class Grade < ActiveRecord::Base
  include GradeStatus
  include Historical
  include MultipleFileAttributes
  include Sanitizable

  belongs_to :course, touch: true
  belongs_to :assignment, touch: true
  belongs_to :assignment_type, touch: true
  belongs_to :student, class_name: "User", touch: true
  belongs_to :team, touch: true
  belongs_to :submission
  belongs_to :group, touch: true # Optional
  belongs_to :graded_by, class_name: "User", touch: true

  has_one :imported_grade, dependent: :destroy
  has_many :earned_badges, dependent: :destroy

  has_many :badges, through: :earned_badges
  accepts_nested_attributes_for :earned_badges,
    reject_if: proc { |a| (a["score"].blank?) }, allow_destroy: true

  before_validation :cache_associations
  before_save :calculate_points
  before_save :zero_points_for_pass_fail
  after_save :check_unlockables

  clean_html :feedback
  multiple_files :grade_files
  releasable_through :assignment

  has_many :grade_files, dependent: :destroy, inverse_of: :grade
  accepts_nested_attributes_for :grade_files

  validates_presence_of :assignment, :assignment_type, :course, :student
  validates :assignment_id, uniqueness: { scope: :student_id }

  delegate :name, :description, :due_at, :assignment_type, :course, to: :assignment

  after_destroy :cache_student_and_team_scores

  scope :completion, -> { where(order: "assignments.due_at ASC", joins: :assignment) }
  scope :order_by_highest_score, -> { order("score DESC") }

  scope :excluded_from_course_score, -> { where excluded_from_course_score: true }
  scope :included_in_course_score, -> { where excluded_from_course_score: false }
  scope :grade_modified, -> { where.not(graded_by_id: nil) }
  scope :positive, -> { where("score > 0")}
  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }
  scope :not_nil, -> { where.not(score: nil)}

  def self.find_or_create(assignment_id,student_id)
    Grade.find_or_create_by(student_id: student_id, assignment_id: assignment_id)
  end

  def self.find_or_create_grades(assignment_id,student_ids)
    student_ids.each do |student_id|
      find_or_create(assignment_id, student_id)
    end
    Grade.where(student_id: student_ids, assignment_id: assignment_id)
  end

  def clear_grade!
    self.raw_points, self.status, self.feedback, self.feedback_read_at,
      self.feedback_reviewed_at, self.graded_at, self.graded_by_id,
      self.adjustment_points_feedback = nil

    self.adjustment_points = 0
    self.feedback_read = self.feedback_reviewed = false
    save
  end

  def grade_modified?
    !self.graded_by_id.nil?
  end

  def feedback_read!
    update_attributes feedback_read: true, feedback_read_at: DateTime.now
  end

  def feedback_reviewed!
    update_attributes feedback_reviewed: true, feedback_reviewed_at: DateTime.now
  end

  # Handle raw points attributes with commas (ex "300,000")
  def raw_points=(rp)
    if rp.class == String
      rp.delete!(",").to_i
    end
    write_attribute(:raw_points, rp)
  end

  def predicted_points
    PredictedEarnedGrade.where(
      student_id: self.student_id,
      assignment_id: self.assignment_id).first.try(:predicted_points) || 0
  end

  def assignment_weight
    assignment_type.weight_for_student(student)
  end

  def cache_student_and_team_scores
    student.cache_course_score_and_level(course_id)
    team = student.team_for_course(course_id)
    return unless team.present?
    team.update_average_score!
    team.update_ranks!
  end

  def check_unlockables
    if self.assignment.is_a_condition?
      self.assignment.unlock_keys.map(&:unlockable).each do |unlockable|
        unlockable.check_unlock_status(student)
      end
    end
    if self.assignment_type.is_a_condition?
      self.assignment_type.unlock_keys.map(&:unlockable).each do |unlockable|
        unlockable.check_unlock_status(student)
      end
    end
  end

  def excluded_by
    User.find(excluded_by_id)
  end

  private

  # full points (with student's weighting)
  def calculate_full_points
    assignment.full_points_for_student(student)
  end

  # totaled points (adds adjustment, without weighting)
  def calculate_final_points
    return nil unless raw_points.present?
    final_points = raw_points + adjustment_points
    final_points >= assignment.threshold_points ? final_points : 0
  end

  # points with student's weighting
  def calculate_score
    return nil unless raw_points.present?
    weighting = assignment_type.student_weightable? ? assignment_weight : 1
    final_points * weighting
  end

  # Calculate all stored points fields before save
  def calculate_points
    self.full_points = calculate_full_points
    self.final_points = calculate_final_points
    self.score = calculate_score
  end

  def cache_associations
    self.student_id ||= submission.try(:student_id)
    self.assignment_id ||= submission.try(:assignment_id)
    self.assignment_type_id ||= assignment.try(:assignment_type_id)
    self.course_id ||= assignment.try(:course_id)
  end

  def zero_points_for_pass_fail
    if self.assignment.pass_fail?
      self.raw_points = 0
      self.final_points = 0
      self.full_points = 0
    end
  end
end
