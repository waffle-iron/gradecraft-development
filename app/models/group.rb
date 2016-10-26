class Group < ActiveRecord::Base
  include Sanitizable

  APPROVED_STATUSES = ["Pending", "Approved", "Rejected"]

  attr_reader :student_tokens

  belongs_to :course

  has_many :assignment_groups, dependent: :destroy, inverse_of: :group
  has_many :assignments, through: :assignment_groups
  accepts_nested_attributes_for :assignment_groups

  has_many :group_memberships, dependent: :destroy
  has_many :students, through: :group_memberships
  accepts_nested_attributes_for :group_memberships

  has_many :grades
  has_many :proposals
  accepts_nested_attributes_for :proposals, allow_destroy: true, reject_if: proc { |a| a["proposal"].blank? }

  has_many :submissions
  has_many :submissions_exports

  has_many :earned_badges, as: :group

  before_validation :cache_associations

  validates_presence_of :name, :approved

  validate :max_group_number_not_exceeded, :min_group_number_met,
    :unique_assignment_per_group_membership, :assignment_group_present

  scope :approved, -> { where approved: "Approved" }
  scope :rejected, -> { where approved: "Rejected" }
  scope :pending, -> { where approved: "Pending" }
  scope :order_by_name, -> { order "name ASC" }

  clean_html :text_proposal

  # Instructors need to approve a group before the group is allowed to proceed
  def approved?
    approved == "Approved"
  end

  def rejected?
    approved == "Rejected"
  end

  def pending?
    approved == "Pending"
  end

  # Group submissions
  def submission_for_assignment(assignment)
    submissions_by_assignment_id[assignment.id].try(:first)
  end

  private

  # Checking to make sure any constraints the instructor has set up around
  # min/max group members are honored
  def min_group_number_met
    return false unless self.assignments.present?
    if self.students.to_a.size < self.assignments.first.min_group_size
      errors.add :base, "You don't have enough group members."
    end
  end

  def max_group_number_not_exceeded
    return false unless self.assignments.present?
    if self.students.to_a.size > self.assignments.first.max_group_size
      errors.add :base, "You have too many group members."
    end
  end

  # Checking to make sure the group is actually working on an assignment
  def assignment_group_present
    if self.assignment_groups.to_a.size == 0
      errors.add :base, "You need to check off which #{(course.assignment_term).downcase} your #{(course.group_term).downcase} will work on."
    end
  end

  # We need to make sure students only belong to one group working on a
  # single assignment
  def unique_assignment_per_group_membership
    assignments.each do |a|
      students.each do |s|
        if s.group_for_assignment(a).present? && s.group_for_assignment(a).id != self.id
          errors.add :base, "#{s.name} is already working on this with another #{(course.group_term)}."
        end
      end
    end
  end

  def submissions_by_assignment_id
    @submissions_by_assignment ||= submissions.group_by(&:assignment_id)
  end

  def cache_associations
    self.course_id ||= assignments.first.try(:course_id)
  end
end
