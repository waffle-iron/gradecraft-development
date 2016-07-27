# return badge assertion as json for the current user's earned badge
class API::Openbadges::BadgeAssertionController < ApplicationController
  def index
    puts "current user is: #{current_user.id} and current course is: #{current_course.id}"
    # badge = EarnedBadge.where(student_id: current_user.id, badge_id: params[:id],
    #   course_id: current_course.id
    # ).first

    # this is a problem, would potentially need to make multiple assertions for a particular badge
    # if it has been earned more than once
    badge = current_user.earned_badge_for_badge(params[:id]).first
    puts "badge is: #{badge.inspect}"
    if (!badge.present?)
      render json: {
        message: "Current user has not earned this badge"
      }, status: 400
    else
      render json: BackpackConnect::Assertions::BadgeAssertion.new(badge,
        current_user, api_openbadges_badge_class_url, { type: "hosted", url: "/someurl" }
      ), status: 200
    end
  end
end
