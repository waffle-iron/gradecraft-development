require_relative "../../services/creates_earned_badge"

class API::EarnedBadgesController < ApplicationController
  # POST /api/earned_badges
  def create
    result = Services::CreatesEarnedBadge.award params[:earned_badge]
    render json: result.earned_badge
  end
end
