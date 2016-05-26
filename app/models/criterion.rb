class Criterion < ActiveRecord::Base
  include Copyable

  belongs_to :rubric
  has_many :levels, dependent: :destroy

  has_many :criterion_grades
  belongs_to :full_credit_level,
    foreign_key: :full_credit_level_id, class_name: "Level"
  attr_accessible :description, :full_credit_level_id, :max_points,
    :meets_expectations_level_id, :meets_expectations_points,
    :name, :order, :rubric_id
  attr_accessor :add_default_levels

  after_initialize :set_defaults
  after_create :generate_default_levels, if: :add_default_levels?
  # after_save :update_full_credit, if: :add_default_levels?

  validates :max_points, presence: true
  validates :name, presence: true, length: { maximum: 30 }
  validates :order, presence: true

  scope :ordered, -> { order(:order) }

  def copy(attributes={})
    ModelCopier.new(self).copy(attributes: attributes,
                               associations: [:levels],
                               options: { overrides: [
                                 ->(copy) { copy.add_default_levels = false }]})
  end

  include DisplayHelpers

  # Mangages a unique level per criteria that meets expectations, and
  # stores the id and points on the Criteria for queries from other levels
  def update_meets_expectations!(level, state)
    return false unless levels.include? level

    # Set only this level as 'meets_expectations'
    if state == true && !level.meets_expectations?
      self.transaction do
        level.update(meets_expectations: true)
        levels.where("id != ?", level.id).update_all(meets_expectations: false)
        update_attributes(
          meets_expectations_level_id: level.id,
          meets_expectations_points: level.points
        )
      end

    # Remove 'meets_expectations' from this criterion
    elsif state == false && level.meets_expectations?
      self.transaction do
        level.update_attributes(meets_expectations: false)
        update_attributes(
          meets_expectations_level_id: nil,
          meets_expectations_points: 0
        )
      end
    end
  end

  def comments_for(student_id)
    self.criterion_grades.where(student_id: student_id).first.try(:comments)
  end

  protected

  def add_default_levels?
    self.add_default_levels == true
  end

  def set_defaults
    self.add_default_levels = true
  end

  def generate_default_levels
    @full_credit_level = create_full_credit_level
    create_no_credit_level
    # update_attributes full_credit_level_id: @full_credit_level[:id]
  end

  def update_full_credit
    find_and_set_full_credit_level unless full_credit_level
    full_credit_level.update_attributes points: max_points
  end

  def find_and_set_full_credit_level
    full_credit_level = levels.where(full_credit: true).first
    full_credit_level ||= create_full_credit_level
    update_attributes full_credit_level_id: full_credit_level[:id]
  end

  def create_full_credit_level
    levels.create(
      name: "Full Credit",
      points: max_points,
      full_credit: true,
      sort_order: 0
    )
  end

  def create_no_credit_level
    levels.create(
      name: "No Credit",
      points: 0,
      no_credit: true,
      sort_order: 1000
    )
  end
end
