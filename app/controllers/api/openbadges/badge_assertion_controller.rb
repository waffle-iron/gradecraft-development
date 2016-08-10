# return badge assertion as json for the current user's earned badge
class API::Openbadges::BadgeAssertionController < ApplicationController
  def index
    #todo issue multiple badges at a time
    earned_badge = current_user.earned_badge_for_id(params[:id])
    if (!earned_badge.present?)
      render json: {
        message: "Current user has not earned this badge"
      }, status: 400
    else
      #badge_verification_id, or user_id, cannot be reliant on current_user since this endpoint will be public
      verification = {
        type: "hosted",
        url: api_openbadges_badge_verification_user_url(badge_verification_id: current_user.id,
          badge_id: earned_badge.id) + ".json"
      }
      render json: BackpackConnect::Assertions::BadgeAssertion.new(earned_badge,
        current_user, "#{api_openbadges_badge_class_url(earned_badge.badge_id)}.json", verification
      ), status: 200
    end
  end
end
