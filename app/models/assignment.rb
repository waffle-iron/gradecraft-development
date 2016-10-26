class Assignment < ActiveRecord::Base
  include Copyable
  include Gradable
  include MultipleFileAttributes
  include Sanitizable
  include ScoreLevelable
  include UploadsMedia
  include UploadsThumbnails
  include UnlockableCondition

  attr_accessor :current_student_grade

  belongs_to :course, touch: true
  belongs_to :assignment_type, -> { order("position ASC") }, touch: true

  has_one :rubric, dependent: :destroy

  multiple_files :assignment_files
  # Preventing malicious content from being submitted
  clean_html :description
  clean_html :purpose

  # For instances where the assignment needs its own unique score levels
  score_levels :assignment_score_levels, -> { order "points" }, dependent: :destroy

  # Student created groups, can connect to multiple assignments and receive
  # group level or individualized feedback
  has_many :assignment_groups, dependent: :destroy
  has_many :groups, through: :assignment_groups

  # Student created submissions to be graded
  has_many :submissions, dependent: :destroy

  has_many :criterion_grades, dependent: :destroy
  has_one :imported_assignment, dependent: :destroy

  # Instructor uploaded resource files
  has_many :assignment_files, dependent: :destroy, inverse_of: :assignment
  accepts_nested_attributes_for :assignment_files

  # Strip points from pass/fail assignments
  before_save :zero_points_for_pass_fail

  before_save :reset_default_for_nil_values

  validates_presence_of :name, :course_id, :assignment_type_id, :grade_scope, :threshold_points

  validates_inclusion_of :student_logged, :required, :accepts_submissions,
  :release_necessary, :visible, :resubmissions_allowed, :include_in_timeline,
  :include_in_predictor, :include_in_to_do, :use_rubric, :accepts_attachments,
  :accepts_text, :accepts_links, :pass_fail, :hide_analytics, :visible_when_locked,
  :show_name_when_locked, :show_points_when_locked, :show_description_when_locked,
  :show_purpose_when_locked, in: [true, false], message: "must be true or false"

  validate :open_before_close, :submissions_after_due, :submissions_after_open
  validate :max_more_than_min
  validates_numericality_of :max_group_size, allow_nil: true, greater_than_or_equal_to: 1
  validates_numericality_of :min_group_size, allow_nil: true, greater_than_or_equal_to: 1

  scope :group_assignments, -> { where grade_scope: "Group" }

  # Filtering Assignments by where in the interface they are displayed
  scope :timelineable, -> { where(include_in_timeline: true) }

  # Sorting assignments by different properties
  scope :chronological, -> { order("due_at ASC") }
  scope :alphabetical, -> { order("name ASC") }
  scope :ordered, -> { order("position ASC") }
  acts_as_list scope: :assignment_type

  # Filtering Assignments by various date properties
  scope :with_dates, -> { where("assignments.due_at IS NOT NULL OR assignments.open_at IS NOT NULL") }

  delegate :student_weightable?, to: :assignment_type

  def copy(attributes={})
    ModelCopier.new(self).copy(attributes: attributes,
                               associations: [:assignment_score_levels],
                               options: { prepend: { name: "Copy of "},
                                          overrides: [->(copy) {
                                 copy.rubric = self.rubric.copy if self.rubric.present?
                               }]})
  end

  def to_json(options = {})
    super(options.merge(only: [:id]))
  end

  def full_points
    super.presence || 0
  end

  def grade_with_rubric?
    use_rubric && rubric.present? && rubric.designed?
  end

  def fetch_or_create_rubric
    return rubric if rubric
    Rubric.create assignment_id: self[:id]
  end

  # Checking to see if an assignment is individually graded
  def is_individual?
    !["Group"].include? grade_scope
  end

  # Checking to see if the assignment is a group assignment
  def has_groups?
    grade_scope=="Group"
  end

  # Custom point total if the class has weighted assignments
  def full_points_for_student(student)
    return 0 unless full_points
    full_points * assignment_type.weight_for_student(student)
  end

  # Checking to see if an assignment is due soon
  def soon?
    future? && due_at < 7.days.from_now
  end

  # helper methods for finding #student_submissions
  def student_submissions
    Submission
      .includes(:submission_files)
      .includes(:student)
      .where(assignment_id: self[:id])
      .to_a # eager-load
  end

  def student_submissions_for_team(team)
    Submission
      .includes(:submission_files)
      .includes(:student)
      .where(assignment_id: self[:id])
      .where("student_id in (select distinct(student_id) from team_memberships where team_id = ?)", team.id)
      .to_a # eager-load
  end

  def student_submissions_with_files
    Submission
      .includes(:submission_files)
      .includes(:student)
      .where(assignment_id: self[:id])
      .where(submissions_with_files_query)
      .to_a # eager-load
  end

  def student_submissions_with_files_for_team(team)
    Submission
      .includes(:submission_files)
      .includes(:student)
      .where(assignment_id: self[:id])
      .where("student_id in (select distinct(student_id) from team_memberships where team_id = ?)", team.id)
      .where(submissions_with_files_query)
      .to_a # eager-load
  end

  def group_submissions_with_files
    Submission
      .includes(:submission_files)
      .includes(:group)
      .where(assignment_id: self[:id])
      .where(submissions_with_files_query)
      .to_a # eager-load
  end

  def student_with_submissions_query
    "select distinct(student_id) from submissions where assignment_id = ?"
  end

  def group_with_submissions_query
    "select distinct(group_id) from submissions where assignment_id = ?"
  end

  def submissions_with_files_query
    "text_comment <> '' or link <> '' or id in (#{present_submission_files_query})"
  end

  def present_submission_files_query
    "select distinct(submission_id) from submission_files where file_missing is null or file_missing = 'f'"
  end

  def missing_submission_files_query
    "select distinct(submission_id) from submission_files where file_missing = ?"
  end

  # #students_with_submissions methods

  def students_with_submissions
    User.order_by_name
      .where("id in (#{student_with_submissions_query})", self.id)
  end

  def students_with_submissions_on_team(team)
    User.order_by_name
      .where(students_with_submissions_on_team_conditions.join(" AND "), self[:id], team.id)
  end

  def groups_with_files
    Group.order_by_name
      .where("id in (#{group_with_submissions_query} and (#{submissions_with_files_query}))", self.id)
  end

  def students_with_text_or_binary_files
    User.order_by_name
      .where("id in (#{student_with_submissions_query} and (#{submissions_with_files_query}))", self.id)
  end

  def students_with_text_or_binary_files_on_team(team)
    User.order_by_name
      .where("id in (#{student_with_submissions_query} and (#{submissions_with_files_query}))", self.id)
      .where("id in (select distinct(student_id) from team_memberships where team_id = ?)", team.id)
  end

  # students and submissions with missing binaries
  def students_with_missing_binaries
    User.order_by_name
      .where("id in (select distinct(student_id) from submissions where assignment_id = ? and id in (#{missing_submission_files_query}))", self.id, true)
  end

  # students and submissions with missing binaries
  def students_with_missing_binaries_on_team(team)
    User.order_by_name
      .where("id in (select distinct(student_id) from submissions where assignment_id = ? and id in (#{missing_submission_files_query}))", self.id, true)
      .where("id in (select distinct(student_id) from team_memberships where team_id = ?)", team.id)
  end

  def submission_files_with_missing_binaries
    SubmissionFile.order("created_at ASC")
      .where(file_missing: true)
      .where("submission_id in (select id from submissions where assignment_id = ?)", self.id)
  end

  def submission_files_with_missing_binaries_for_team(team)
    SubmissionFile.order("created_at ASC")
      .where(file_missing: true)
      .where("submission_id in (select id from submissions where assignment_id = ?)", self.id)
      .where("submission_id in (select id from submissions where student_id in (select distinct(student_id) from team_memberships where team_id = ?))", team.id)
  end

  # The below four are the Quick Grading Types, can be set at either the
  # assignment or assignment type level
  def grade_checkboxes?
    mass_grade_type == "Checkbox"
  end

  def grade_select?
    mass_grade_type == "Select List" && has_levels?
  end

  def grade_radio?
    mass_grade_type == "Radio Buttons" && has_levels?
  end

  def grade_text?
    mass_grade_type == "Text"
  end

  def has_levels?
    assignment_score_levels.present?
  end

  # Finding what grade level was earned for a particular assignment
  def grade_level(grade)
    assignment_score_levels.find { |asl| grade.raw_points == asl.points }.try(:name)
  end

  def future?
    !due_at.nil? && due_at >= Time.now
  end

  def opened?
    open_at.nil? || open_at < Time.now
  end

  def overdue?
    !due_at.nil? && due_at < Time.now
  end

  def accepting_submissions?
    accepts_submissions_until.nil? || accepts_submissions_until > Time.now
  end

  # No longer accepting submissions.
  def submissions_have_closed?
    !accepts_submissions_until.nil? && accepts_submissions_until < Time.now
  end

  # TODO: We need a closed? (or has_closed?) method for assignments with
  # or without submissions

  # Checking to see if the assignment is still open and accepting submissons
  def open?
    opened? && (!overdue? || accepting_submissions?)
  end

  # Calculating attendance rate, which tallies number of people who have
  # positive grades for attendance divided by total number of students in class
  def completion_rate(course)
    return 0 if course.graded_student_count.zero?
    ((grade_count / course.graded_student_count.to_f) * 100).round(2)
  end

  # Counting the percentage of submissions from the entire class
  def submission_rate(course)
    return 0 if course.graded_student_count.zero?
    ((submissions.count / course.graded_student_count.to_f) * 100).round(2)
  end

  def grade_import(students, options = {})
    GradeExporter.new.export_grades(self, students, options)
  end

  # Creating an array with the set of scores earned on the assignment
  def percentage_score_earned
    { scores: earned_score_count.collect { |s| { data: s[1], name: s[0] }}}
  end

  private

  def students_with_submissions_on_team_conditions
    ["id in (#{student_with_submissions_query})",
     "id in (select distinct(student_id) from team_memberships where team_id = ?)"]
  end

  def open_before_close
    if (due_at.present? && open_at.present?) && (due_at < open_at)
      errors.add :base, "Due date must be after open date."
    end
  end

  def submissions_after_due
    if (accepts_submissions_until.present? && due_at.present?) && (accepts_submissions_until < due_at)
      errors.add :base, "Submission accept date must be after due date."
    end
  end

  def submissions_after_open
    if (accepts_submissions_until.present? && open_at.present?) && (accepts_submissions_until < open_at)
      errors.add :base, "Submission accept date must be after open date."
    end
  end

  def max_more_than_min
    if (max_group_size? && min_group_size?) && (max_group_size < min_group_size)
      errors.add :base, "Maximum group size must be greater than minimum group size."
    end
  end

  def zero_points_for_pass_fail
    self.full_points = 0 if self.pass_fail?
    self.threshold_points = 0 if self.pass_fail?
  end

  def reset_default_for_nil_values
    self.threshold_points = 0 if self.threshold_points.nil?
  end
end
