require_relative "../creates_grade_using_rubric"

module Services
  module Actions
    class IteratesCreatesGradeUsingRubric
      extend LightService::Action

      expects :raw_params, :user

      executed do |context|
        begin
          group = Group.find(context[:raw_params]["group_id"])
        rescue ActiveRecord::RecordNotFound
          context.fail!("Unable to find group", error_code: 404)
          next context
        end

        user = context[:user]
        group.students.each do |student|
          params = context[:raw_params].deep_dup
          params["student_id"] = student.id
          params["group_id"] = group.id
          context.add_to_context Services::CreatesGradeUsingRubric.create(params, user)
        end
      end
    end
  end
end
