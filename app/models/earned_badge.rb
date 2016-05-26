class EarnedBadge < ActiveRecord::Base
  attr_accessible :score, :feedback, :student, :badge, :student_id, :badge_id,
    :submission_id, :course_id, :assignment_id, :level_id, :criterion_id,
    :student_visible, :grade, :_destroy, :course, :grade_id, :feedback

  STATUSES= ["Predicted", "Earned"]

  before_validation :cache_associations

  belongs_to :course, touch: true
  belongs_to :badge
  belongs_to :student, class_name: "User", touch: true
  belongs_to :submission # Optional
  belongs_to :task # Optional
  belongs_to :grade # Optional
  belongs_to :group, polymorphic: true # Optional
  has_many :badge_files, through: :badge

  validates_presence_of :badge, :course, :student

  after_save :check_unlockables

  # validates :badge_id, uniqueness: {scope: :grade_id}

  # Some badges can only be earned once - we check on award if that's the case
  validate :multiple_allowed

  delegate :name, :description, :icon, to: :badge

  scope :for_course, ->(course) { where(course_id: course.id) }
  scope :for_student, ->(student) { where(student_id: student.id) }
  scope :student_visible, -> { where(student_visible: true) }
  scope :order_by_created_at, -> { order("created_at ASC") }

  def check_unlockables
    if self.badge.is_a_condition?
      unlock_conditions = UnlockCondition.where(condition: self.badge).each do |condition|
        unlockable = condition.unlockable
        unlockable.check_unlock_status(student)
      end
    end
  end

  private

  def cache_associations
    self.course_id ||= badge.try(:course_id)
    self.score ||= badge.try(:point_total) || 0
    self.student_visible = GradeProctor.new(grade).viewable? if grade.present?
    true
  end

  def multiple_allowed
    if !self.badge.can_earn_multiple_times? && self.badge.earned_badge_for_student(self.student)
      errors.add :base, " Oops, they've already earned the '#{name}' #{course.badge_term.downcase}."
    end
  end

end
