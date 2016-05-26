json.challenges @challenges do |challenge|
  next unless challenge.visible_for_student?(@student)
  json.merge! challenge.attributes

  # boolean states for icons
  json.has_info !challenge.description.blank?

  json.score_levels challenge.challenge_score_levels.map {
    |csl| {name: csl.name, value: csl.value}
  }

  json.prediction challenge.prediction

  json.grade challenge.grade
end

json.term_for_challenges term_for :challenges
json.update_challenges @update_challenges
