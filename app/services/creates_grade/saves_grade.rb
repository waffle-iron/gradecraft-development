module Services
  module Actions
    class SavesGrade
      extend LightService::Action

      expects :grade
      promises :student_visible_status

      executed do |context|
        grade = context[:grade]
        context.fail_with_rollback!("The grade is invalid and cannot be saved", error_code: 422) \
          unless grade.save
        # warning: LightService doesn't set context keys to false, will be nil !
        context[:student_visible_status] = GradeProctor.new(grade).viewable?
      end
    end
  end
end
