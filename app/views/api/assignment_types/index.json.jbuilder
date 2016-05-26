json.data @assignment_types do |assignment_type|
  json.type "assignment types"
  json.id assignment_type.id.to_s
  json.attributes do
    json.merge! assignment_type.attributes
    json.total_points assignment_type.total_points
    if assignment_type.student_weightable?
      json.student_weight @student.weight_for_assignment_type(assignment_type)
    end
    json.is_capped assignment_type.is_capped?
  end
end

json.meta do
  json.term_for_assignment_type term_for :assignment_type
  json.term_for_weights term_for :weights
  json.update_weights @update_weights

  json.total_assignment_weight current_course.try(:total_assignment_weight)
  json.assignment_weight_close_at current_course.try(:assignment_weight_close_at)
  json.max_assignment_weight current_course.max_assignment_weight
  json.max_assignment_types_weighted current_course.max_assignment_types_weighted
  json.default_assignment_weight current_course.default_assignment_weight
end
