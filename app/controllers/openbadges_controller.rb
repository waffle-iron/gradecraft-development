require "backpack_connect"

class OpenbadgesController < ApplicationController
  before_action :set_authenticator, only: [:push]

  # Callback for backpack connect api; expects auth credentials
  def connect
    @authenticator = BackpackConnect::Authenticator.new(params)

    if @authenticator.error.nil?
      session[:backpack_authenticator] = @authenticator
      redirect_to action: :push, id: params[:current_badge]
    else
      redirect_on_completion({ error: "Unable to establish connection to backpack" })
    end
  end

  # rubocop:disable AndOr
  def push
    @earned_badge = current_user.earned_badge_for_id(params[:id])

    redirect_to badges_path,
      alert: "Current user has not earned this badge" and return unless @earned_badge.present?
    verification = {
      type: "hosted",
      url: api_openbadges_badge_verification_user_url(badge_verification_id: current_user.id,
        badge_id: @earned_badge.id) + ".json"
    }
    assertion = BackpackConnect::Assertions::BadgeAssertion.new(
      @earned_badge, current_user,
      "#{api_openbadges_badge_class_url(@earned_badge.badge_id)}.json", verification)
    backpack_issuer = BackpackConnect::API.new(@authenticator)
    response = backpack_issuer.issue assertion
    redirect_push_response(response)
  end

  private

  def set_authenticator
    @authenticator ||= session[:backpack_authenticator]
    redirect_to badges_path, status: 401 and return if @authenticator.nil?
  end

  def redirect_push_response(response)
    case response.code
    when 200
      redirect_on_completion({ success: "Badge was successfully issued" })
    when 401
      redirect_to badges_path, status: 401
    else
      redirect_on_completion({ alert: "An error occurred (#{response.parsed_response["message"]})" })
    end
  end

  def redirect_on_completion(options)
    if params[:current_badge].nil?
      redirect_to badges_path, flash: options
    else
      redirect_to badge_path(params[:current_badge]), flash: options
    end
  end
end
