require "backpack_connect"

class API::Openbadges::BackpackController < ApplicationController
  before_filter :ensure_authenticated, only: [:issue]

  # Backpack Connect callback for retrieving auth credentials
  def connect
    @authenticator = BackpackConnect::Authenticator.new params
    if (@authenticator.error.nil?)
      session[:backpack_authenticator] = @authenticator
      #todo probably should be a regular controller action; user may need to retry the issue request
      render json: {
        message: "Access successfully granted for #{@authenticator.expires} seconds"
      }, status: 200
    else
      render json: {
        message: "Unable to establish connection to backpack"
      }, status: 400
    end
  end

  #todo should possibly be a post
  # Issue the badge
  # GET /api/openbadges/backpack/:id/issue
  def issue
    earned_badge = current_user.earned_badge_for_id(params[:id])
    unless earned_badge.present?
      render json: { message: "Current user has not earned this badge" }, status: 400 and return
    end
    verification = {
      type: "hosted",
      url: api_openbadges_badge_verification_user_url(badge_verification_id: current_user.id,
        badge_id: earned_badge.id) + ".json"
    }
    assertion = BackpackConnect::Assertions::BadgeAssertion.new(earned_badge,
      current_user, "#{api_openbadges_badge_class_url(earned_badge.badge_id)}.json", verification
    )
    backpackIssuer = BackpackConnect::API.new(@authenticator)
    response = backpackIssuer.issue assertion
    check_response response
  end

  private

  def ensure_authenticated
    @authenticator ||= session[:backpack_authenticator]
    render json: {
      message: "Not authorized"
    }, status: 401 and return unless @authenticator.present?
  end

  def check_response(response)
    case response.code
      when 200
        render json: { message: "Success" }, status: 200
      when 401
        render json: { message: "Authentication Failed" }, status: 401
      else
        render json: { message: "#{response.parsed_response}" }, status: response.code
    end
  end
end
