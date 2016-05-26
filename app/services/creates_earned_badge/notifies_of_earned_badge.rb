module Services
  module Actions
    class NotifiesOfEarnedBadge
      extend LightService::Action

      expects :earned_badge

      executed do |context|
        if context.earned_badge.student_visible?
          NotificationMailer.earned_badge_awarded(context.earned_badge.id)
            .deliver_now
        end
      end
    end
  end
end
