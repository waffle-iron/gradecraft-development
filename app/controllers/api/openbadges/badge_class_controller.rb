class API::Openbadges::BadgeClassController < ApplicationController

  # Represent the given badge as an OpenBadges assertion of type BadgeClass
  # Takes an earned badge id
  def index
    badge = EarnedBadge.find_by_id(params[:id])

    if !badge.present?
      render json: { message: "Badge not found" }, status: 401
    else
      issuer = "#{api_openbadges_issuer_organization_index_url}.json"
      render json: BackpackConnect::Assertions::BadgeClass.new(badge, issuer, request.host_with_port)
    end
  end
end
