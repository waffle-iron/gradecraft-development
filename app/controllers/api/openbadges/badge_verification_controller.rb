class API::Openbadges::BadgeVerificationController < ApplicationController
  def index
    user = User.find_by_id(params[:id])
    badge = Badge.find_by_id(params[:badge_id])
    render json: {
      message: "Unable to verify badge", success: false
    }, status: 400 unless user.present? && badge.present?
    render json: BackpackConnect::BadgeAssertion.new(badge)
  end
end
