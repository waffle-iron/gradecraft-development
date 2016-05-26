json.array! badges do |badge|
  json.(badge, :id, :name, :description, :point_total)

  if student_id
    json.student_earned_badges badge.earned_badges.where(student_id: student_id)
  end

  json.multiple badge.can_earn_multiple_times
  json.icon badge.icon.url
end
