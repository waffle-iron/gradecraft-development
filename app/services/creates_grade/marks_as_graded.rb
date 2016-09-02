module Services
  module Actions
    class MarksAsGraded
      extend LightService::Action

      expects :grade, :user

      executed do |context|
        context[:grade].instructor_modified = true
        context[:grade].graded_at = DateTime.now
        context[:grade].graded_by_id = context[:user].id
      end
    end
  end
end
