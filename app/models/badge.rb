class Badge < ActiveRecord::Base
  include Copyable
  include UnlockableCondition
  include MultipleFileAttributes

  attr_accessible :name, :description, :icon, :visible, :point_total,
    :can_earn_multiple_times, :earned_badges, :earned_badges_attributes,
    :badge_file_ids, :badge_files_attributes, :badge_file, :position,
    :visible_when_locked, :course_id, :course, :show_name_when_locked,
    :show_points_when_locked, :show_description_when_locked

  # grade points available to the predictor from the assignment controller
  attr_accessor :prediction

  acts_as_list scope: :course

  mount_uploader :icon, BadgeIconUploader

  has_many :earned_badges, dependent: :destroy
  has_many :predicted_earned_badges, dependent: :destroy

  belongs_to :course, touch: true

  accepts_nested_attributes_for :earned_badges, allow_destroy: true, reject_if: proc { |a| a["score"].blank? }

  multiple_files :badge_files
  has_many :badge_files, dependent: :destroy
  accepts_nested_attributes_for :badge_files

  validates_presence_of :course, :name
  validates_numericality_of :point_total, allow_blank: true

  scope :visible, -> { where(visible: true) }

  default_scope { order("position ASC") }

  def can_earn_multiple_times
    super || false
  end

  # indexed badges
  def awarded_count
    earned_badges.student_visible.count
  end

  # badges per role
  def earned_badges_by_student_id
    @earned_badges_by_student_id ||= earned_badges.group_by { |eb| [eb.student_id] }
  end

  def earned_badge_for_student(student)
    earned_badges_by_student_id[[student.id]].try(:first)
  end

  def find_or_create_predicted_earned_badge(student_id)
    if student_id == 0
      NullPredictedEarnedBadge.new
    else
      PredictedEarnedBadge.find_or_create_by(student_id: student_id, badge_id: self.id)
    end
  end

  # Counting how many times a particular student has earned this badge
  def earned_badge_count_for_student(student)
    earned_badges.where(student_id: student.id, student_visible: true).count
  end

  def earned_badge_total_points(student)
    earned_badges.where(
      student_id: student,
      student_visible: true
    ).pluck("score").map(&:to_i).sum
  end
end
