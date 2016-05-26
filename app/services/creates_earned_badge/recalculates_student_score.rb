module Services
  module Actions
    class RecalculatesStudentScore
      extend LightService::Action

      expects :earned_badge

      executed do |context|
        if context.earned_badge.badge.point_total?
          ScoreRecalculatorJob.new(user_id: context.earned_badge.student_id,
                                   course_id: context.earned_badge.course_id)
            .enqueue
        end
      end
    end
  end
end
