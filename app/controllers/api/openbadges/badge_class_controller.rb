class API::Openbadges::BadgeClassController < ApplicationController
  def index
    badge = current_course.badges.find(params[:id])
    render json: BackpackConnect::Assertions::BadgeClass.new(badge)
  end
end
