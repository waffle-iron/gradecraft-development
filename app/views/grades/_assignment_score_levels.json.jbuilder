json.array! assignment_score_levels do |score_level|
  json.(score_level, :id, :name, :value, :assignment_id)
end
