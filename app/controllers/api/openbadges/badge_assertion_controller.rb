# return badge assertion as json for the current user's earned badge
class API::Openbadges::BadgeAssertionController < ApplicationController
  def index
    #todo issue multiple badges at a time
    badge = current_user.earned_badge_for_badge(params[:id]).first
    if (!badge.present?)
      render json: {
        message: "Current user has not earned this badge"
      }, status: 400
    else
      verification = { type: "hosted", url: "/todo/verification_url" }
      render json: BackpackConnect::Assertions::BadgeAssertion.new(badge,
        current_user, badges_url(badge.badge_id), verification
      ), status: 200
    end
  end
end
