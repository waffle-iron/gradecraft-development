class Submission < ActiveRecord::Base
  attr_accessible :task, :task_id, :assignment, :assignment_id,
    :assignment_type_id, :group, :group_id, :link, :student, :student_id,
    :creator, :creator_id, :text_comment, :submission_file, :submitted_at,
    :submission_files_attributes, :submission_files, :course_id, :updated_at,
    :submission_file_ids

  include Historical
  include MultipleFileAttributes
  include Sanitizable

  belongs_to :task, touch: true
  belongs_to :assignment, touch: true
  belongs_to :student, class_name: "User", touch: true
  belongs_to :creator, class_name: "User", touch: true
  belongs_to :group, touch: true
  belongs_to :course, touch: true

  after_save :check_unlockables

  has_one :grade
  has_one :assignment_weight, through: :assignment

  accepts_nested_attributes_for :grade
  has_many :submission_files, dependent: :destroy, autosave: true
  accepts_nested_attributes_for :submission_files

  scope :with_grade, -> do
    joins("INNER JOIN grades ON "\
      "grades.assignment_id = submissions.assignment_id AND "\
      "(grades.group_id = submissions.group_id OR "\
      "grades.student_id = submissions.student_id)")
  end

  scope :ungraded, -> do
    includes(:assignment, :group, :student)
      .where.not(id: with_grade.where(grades: { status: ["Graded", "Released"] }))
  end

  scope :resubmitted, -> { includes(:grade)
    .where(grades: { status: ["Graded", "Released"] })
    .where("grades.graded_at < submitted_at")
  }
  scope :order_by_submitted, -> { order("submitted_at ASC") }
  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }

  before_validation :cache_associations

  validates_uniqueness_of :task, scope: :student, allow_nil: true
  validates :link, format: URI::regexp(%w(http https)), allow_blank: true
  validates :assignment, presence: true
  validates_with SubmissionValidator

  clean_html :text_comment
  multiple_files :submission_files

  def graded_at
    grade.graded_at if graded?
  end

  def graded?
    !ungraded?
  end

  # Grabbing any submission that has NO instructor-defined grade (if the
  # student has predicted the grade, it'll exist, but we still don't want to
  # catch those here)
  def ungraded?
    !grade || grade.status == nil
  end

  # Used to report to the user that a change will be a resubmission because this
  # submission is already graded.
  def will_be_resubmitted?
    graded?
  end

  # this is transitive so that once it is graded again, then
  # it will no longer be resubmitted
  def resubmitted?
    graded? && !graded_at.nil? && !submitted_at.nil? && graded_at < submitted_at
  end

  # Getting the name of the student who submitted the work
  def name
    student.name
  end

  # Checking to see if a submission was turned in late
  def late?
    created_at > self.assignment.due_at if self.assignment.due_at.present?
  end

  def has_multiple_components?
    count = 0
    count += submission_files.count
    if link.present?
      count += 1
    end
    if text_comment.present?
      count +=1
    end
    return true if count > 1
    false
  end

  def check_unlockables
    if self.assignment.is_a_condition?
      unlock_conditions = UnlockCondition.where(condition_id: self.assignment.id, condition_type: "Assignment").each do |condition|
        unlockable = condition.unlockable
        if self.assignment.has_groups?
          self.group.students.each do |student|
            unlockable.check_unlock_status(student)
          end
        else
          unlockable.check_unlock_status(student)
        end
      end
    end
  end

  def process_unconfirmed_files
    submission_files.unconfirmed.each do |submission_file|
      submission_file.check_and_set_confirmed_status
    end
  end

  def confirm_all_files
    submission_files.each do |submission_file|
      submission_file.check_and_set_confirmed_status
    end
  end

  private

  def cache_associations
    if task
      self.assignment_id ||= task.assignment_id
      self.assignment_type ||= task.assignment_type
      self.course_id ||= task.assignment.course_id
    end
    self.assignment_id ||= assignment.id
    self.assignment_type ||= assignment.assignment_type
    self.course_id ||= assignment.course_id
  end
end
