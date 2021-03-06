json.data @grades do |grade|
  json.type "grades"
  json.id   grade.id.to_s

  json.attributes do
    json.id                         grade.id
    json.assignment_id              grade.assignment_id
    json.student_id                 grade.student_id
    json.feedback                   grade.feedback
    json.status                     grade.status
    json.adjustment_points          grade.adjustment_points
    json.adjustment_points_feedback grade.adjustment_points_feedback
  end
end

json.meta do
  json.student_ids @student_ids
  json.grade_status_options @grade_status_options
end

