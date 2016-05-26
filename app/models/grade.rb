class Grade < ActiveRecord::Base
  include GradeStatus
  include Historical
  include MultipleFileAttributes
  include Sanitizable

  attr_accessible :_destroy, :adjustment_points, :adjustment_points_feedback,
    :assignment, :assignment_id, :assignment_type_id, :assignments_attributes,
    :course_id, :earned_badges, :earned_badges_attributes, :excluded_by,
    :excluded_date, :excluded_from_course_score, :feedback, :feedback_read,
    :feedback_read_at, :feedback_reviewed, :feedback_reviewed_at, :final_score,
    :grade_file, :grade_file_ids, :grade_files_attributes, :graded_at,
    :graded_by_id, :group, :group_id, :group_type, :instructor_modified,
    :is_custom_value, :pass_fail_status, :point_total, :raw_score, :student,
    :student_id, :submission, :submission_id, :task, :task_id, :team_id

  belongs_to :course, touch: true
  belongs_to :assignment, touch: true
  belongs_to :assignment_type, touch: true
  belongs_to :student, class_name: "User", touch: true
  belongs_to :team, touch: true
  belongs_to :submission
  belongs_to :task, touch: true # Optional
  belongs_to :group, polymorphic: true, touch: true # Optional
  belongs_to :graded_by, class_name: "User", touch: true

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

  has_many :grade_files, dependent: :destroy
  accepts_nested_attributes_for :grade_files

  validates_presence_of :assignment, :assignment_type, :course, :student
  validates :assignment_id, uniqueness: { scope: :student_id }

  delegate :name, :description, :due_at, :assignment_type, :course, to: :assignment

  after_destroy :save_student_and_team_scores

  scope :completion, -> { where(order: "assignments.due_at ASC", joins: :assignment) }

  scope :excluded_from_course_score, -> { where excluded_from_course_score: true }
  scope :included_in_course_score, -> { where excluded_from_course_score: false }
  scope :no_status, -> { instructor_modified.where(status: ["", nil])}
  scope :instructor_modified, -> { where instructor_modified: true }
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

  def feedback_read!
    update_attributes feedback_read: true, feedback_read_at: DateTime.now
  end

  def feedback_reviewed!
    update_attributes feedback_reviewed: true, feedback_reviewed_at: DateTime.now
  end

  # Handle raw score attributes with commas (ex "300,000")
  def raw_score=(rs)
    if rs.class == String
      rs.delete!(",").to_i
    end
    write_attribute(:raw_score,rs)
  end

  # Temporary Helper for grade.final_score, grade.raw_score:
  #
  # This method handles grades saved before adjustment_points was added,
  # when final_score was on the model but was always nil.
  #
  # This will allow views to default to the raw_score if the final_score
  # is not available.
  #
  # TODO between semesters:
  #  * run rake task to calculate update all grades with final scores
  #  * change codebase and add migrations to standardize points/score nomenclature
  #    -  point_total -> full_points
  #    -  raw_score -> raw_points
  #    -  final_score -> final_points
  #  * remove this method, but keep calls to grade.final_points in the views
  #
  def final_points
    final_score || raw_score
  end

  def predicted_points
    PredictedEarnedGrade.where(
      student_id: self.student.id,
      assignment_id: self.assignment.id).first.try(:predicted_points) || 0
  end

  def assignment_weight
    assignment.weight_for_student(student)
  end

  def has_feedback?
    feedback.present?
  end

  # @mz todo: port this over to cache_team_and_student_scores once
  # related methods have tests
  # want to make sure that nothing depends on the output of this method
  def save_student_and_team_scores
    self.student.cache_course_score(self.course.id)
    if self.course.has_teams? && self.student.team_for_course(self.course).present?
      self.student.team_for_course(self.course).cache_score
    end
  end

  # @mz TODO: add specs
  def cache_student_and_team_scores
    { cached_student_score: cache_student_score,
      cached_team_score: cache_team_score,
      student_id: self.student.try(:id),
      team_id: cached_student_team.try(:id)
    }.merge(cached_score_failure_information)
  end

  def check_unlockables
    if self.assignment.is_a_condition?
      unlock_conditions = UnlockCondition.where(condition_id: self.assignment.id, condition_type: "Assignment").each do |condition|
        if condition.unlockable_type == "Assignment"
          unlockable = Assignment.find(condition.unlockable_id)
          unlockable.check_unlock_status(student)
        elsif condition.unlockable_type == "Badge"
          unlockable = Badge.find(condition.unlockable_id)
          unlockable.check_unlock_status(student)
        end
      end
    end
  end

  def excluded_by
    User.find(excluded_by_id)
  end

  private

  # full points (with student's weighting)
  def calculate_point_total
    assignment.point_total_for_student(student)
  end

  # totaled points (adds adjustment, without weighting)
  def calculate_final_score
    return nil unless raw_score.present?
    final_score = raw_score + adjustment_points
    final_score > assignment.threshold_points ? final_score : 0
  end

  # points with student's weighting
  def calculate_score
    return nil unless raw_score.present?
    weighting = assignment_type.student_weightable? ? assignment_weight : 1
    (final_score * weighting).round
  end

  # Calculate all stored points fields before save
  def calculate_points
    self.point_total = calculate_point_total
    self.final_score = calculate_final_score
    self.score = calculate_score
  end

  def save_student
    return unless self.raw_score_changed? || self.status_changed?
    student.save
  end

  def save_team
    if course.has_teams? && student.team_for_course(course).present?
      student.team_for_course(course).save
    end
  end

  def cache_associations
    self.student_id ||= submission.try(:student_id)
    self.task_id ||= submission.try(:task_id)
    self.assignment_id ||= submission.try(:assignment_id) || task.try(:assignment_id)
    self.assignment_type_id ||= assignment.try(:assignment_type_id)
    self.course_id ||= assignment.try(:course_id)
    # self.team_id ||= student.team_for_course(course).try(:id)
  end

  def zero_points_for_pass_fail
    if self.assignment.pass_fail?
      self.raw_score = 0
      self.final_score = 0
      self.point_total = 0
    end
  end

  def duplicate_badge_for_grade
    if self.earned_badges.where(badge_id: earned_badge.badge_id).persisted?
      errors.add("")
    end
  end

  def cached_student_team
    @team ||= student.team_for_course(course)
  end

  # @mz TODO: add specs
  def cache_student_score
    @student = self.student
    @student_update_successful = @student.cache_course_score(self.course.id)
  end

  # @mz TODO: add specs, improve the syntax here
  def cache_team_score
    if course.has_teams? && student.team_for_course(course).present?
      @team = cached_student_team
      @team_update_successful = @team.update_revised_team_score
      @team_update_successful ? @team.score : false
    end
  end

  def cached_score_failure_information
    failure_attrs = {}
    if course.has_teams? && student.team_for_course(course).present?
      unless @team_update_successful
        failure_attrs.merge! team: @team.attributes
      end

      unless @student_update_successful
        failure_attrs.merge! student: @student.attributes
      end

      unless @team_update_successful && @student_update_successful
        failure_attrs.merge! grade: self.attributes
      end
    end

    failure_attrs
  end
end
