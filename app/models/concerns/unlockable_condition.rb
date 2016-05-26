module UnlockableCondition
  extend ActiveSupport::Concern

  included do
    attr_accessible :unlock_conditions, :unlock_conditions_attributes

    has_many :unlock_conditions, as: :unlockable, dependent: :destroy
    has_many :unlock_keys, class_name: "UnlockCondition",
      foreign_key: :condition_id, dependent: :destroy
    has_many :unlock_states, as: :unlockable, dependent: :destroy

    accepts_nested_attributes_for :unlock_conditions, allow_destroy: true,
      reject_if: proc { |uc| uc["condition_type"].blank? || uc["condition_id"].blank? }
  end

  def check_unlock_status(student)
    unlocked = unlock_condition_count_to_meet == unlock_condition_count_met_for(student)
    unlock_state = unlock_states.where(student_id: student.id).first if unlocked
    unlock_state ||= unlock_states.build(student_id: student.id,
                                         unlockable_id: self.id,
                                         unlockable_type: self.class)
    unlock_state.unlocked = unlocked
    unlock_state.save
    unlock_state
  end

  def find_or_create_unlock_state(student_id)
    UnlockState.find_or_create_by(student_id: student_id, unlockable: self)
  end

  def is_a_condition?
    self.unlock_keys.present?
  end

  def is_unlockable?
    self.unlock_conditions.present?
  end

  def is_unlocked_for_student?(student)
    return true unless unlock_conditions.present?
    unlock_state = unlock_states.where(student_id: student.id).first
    unlock_state.present? && unlock_state.is_unlocked?
  end

  def is_unlocked_for_group?(group)
    return true unless unlock_conditions.present?

    if group.present?
      goal = group.students.count
      achieved = 0
      group.students.each do |student|
        unlock_state = unlock_states.where(student_id: student.id).first
        if unlock_state.present? && unlock_state.is_unlocked?
          achieved += 1
        end
      end
      if goal == achieved
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def unlockable
    UnlockCondition.where(condition_id: self.id, condition_type: self.class.name)
      .first.unlockable
  end

  def unlock_condition_count_to_meet
    self.unlock_conditions.count
  end

  def unlock_condition_count_met_for(student)
    self.unlock_conditions
      .select { |condition| condition.is_complete?(student) }
      .size
  end

  def visible_for_student?(student)
    (is_unlockable? &&
     (visible_when_locked? || is_unlocked_for_student?(student))) ||
    (!is_unlockable? && visible?)
  end

  def description_visible_for_student?(student)
    (is_unlockable? &&
      (visible_when_locked? && show_description_when_locked? ||
     is_unlocked_for_student?(student))) ||
    (!is_unlockable? && visible?)
  end

  def purpose_visible_for_student?(student)
    (is_unlockable? &&
      (visible_when_locked? && show_purpose_when_locked? ||
     is_unlocked_for_student?(student))) ||
    (!is_unlockable? && visible?)
  end

  def points_visible_for_student?(student)
    (is_unlockable? &&
      (visible_when_locked? && show_points_when_locked? ||
     is_unlocked_for_student?(student))) ||
    (!is_unlockable? && visible?)
  end

  def name_visible_for_student?(student)
    (is_unlockable? &&
      (visible_when_locked? && show_name_when_locked? ||
     is_unlocked_for_student?(student))) ||
    (!is_unlockable? && visible?)
  end
end
