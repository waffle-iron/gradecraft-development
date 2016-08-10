class API::Openbadges::BadgeVerificationController < ApplicationController
  #todo make public
  def index
    user = User.find_by_id(params[:badge_verification_id])
    if (!user.present?)
      render json: { message: "User not found" }, status: 404 and return
    end
    earned_badge = user.earned_badge_for_id(params[:badge_id])
    if (earned_badge.nil?)
      render json: { message: "Unable to verify badge" }, status: 400
    else
      render json: { message: "Badge successfully verified" }, status: 200
    end
  end
end
