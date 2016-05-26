module Services
  module Actions
    class CreatesEarnedBadge
      extend LightService::Action

      expects :attributes
      promises :earned_badge

      executed do |context|
        context.earned_badge = EarnedBadge.new context.attributes
        unless context.earned_badge.save
          message = "The earned badge is invalid and cannot be saved"
          context.fail_with_rollback! message
        end
      end
    end
  end
end
