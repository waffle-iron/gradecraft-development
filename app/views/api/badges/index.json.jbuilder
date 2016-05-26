json.data @badges do |badge|
  next unless BadgeProctor.new(badge).viewable?(current_user)
  json.type "badges"
  json.id   badge.id.to_s
  json.attributes do
    json.merge! badge.attributes
    json.icon badge.icon.url
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
end
