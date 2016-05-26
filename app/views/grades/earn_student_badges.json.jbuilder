json.array! @earned_badges do |earned_badge|
  json.(earned_badge, :id, :student_id, :badge_id, :grade_id, :assignment_id,
    :score)
end
