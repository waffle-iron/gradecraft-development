json.data @assignments do |assignment|
  next unless assignment.point_total > 0 || assignment.pass_fail?
  next unless assignment.visible_for_student?(assignment.student)
  next unless assignment.include_in_predictor?
  json.type "assignments"
  json.id assignment.id.to_s
  json.attributes do
    json.merge! assignment.attributes

    json.predictor_display_type assignment.predictor_display_type

    json.score_levels assignment.score_levels unless assignment.score_levels.empty?
    json.unlock_conditions assignment.unlock_conditions unless assignment.unlock_conditions.empty?
    json.unlock_keys assignment.unlock_keys unless assignment.unlock_keys.empty?

    json.prediction assignment.prediction

    json.grade do
      json.merge! assignment.grade.attributes
      json.pass_fail_status assignment.grade.pass_fail_status if assignment.pass_fail
    end
  end
end

json.meta do
  json.term_for_assignment term_for :assignment
  json.term_for_pass current_course.pass_term
  json.term_for_fail current_course.fail_term
  json.update_assignments @assignments.permission_to_update?
end
