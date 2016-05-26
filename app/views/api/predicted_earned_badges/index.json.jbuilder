json.data @badges do |badge|
  next unless badge.visible_for_student?(@student)
  json.type "badges"
  json.id   badge.id.to_s
  json.attributes do
    json.merge! badge.attributes
    json.icon badge.icon.url
    json.total_earned_points badge.earned_badge_total_points(@student)
    json.earned_badge_count badge.earned_badge_count_for_student(@student)

    json.prediction badge.prediction

    # boolean states for icons
    json.has_info !badge.description.blank?

    json.is_locked !badge.is_unlocked_for_student?(@student)

    json.has_been_unlocked badge.is_unlockable? && badge.is_unlocked_for_student?(@student)
    if badge.is_unlockable?
      json.unlock_conditions badge.unlock_conditions.map {
        |condition| "#{condition.name} must be #{condition.condition_state}"
      }
    end

    json.is_a_condition badge.is_a_condition?
    if badge.is_a_condition?
      json.unlock_keys badge.unlock_keys.map {
        |key| "#{key.unlockable.name} is unlocked by #{key.condition_state} #{key.condition.name}"
        }
    end
  end
end

json.meta do
  json.term_for_badges term_for :badges
  json.term_for_badge term_for :badge
  json.update_badges @update_badges
end

