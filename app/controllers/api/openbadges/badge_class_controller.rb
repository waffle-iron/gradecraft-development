class API::Openbadges::BadgeClassController < ApplicationController

  # Represent the badge as an OpenBadges assertion of type BadgeClass
  def index
    badge = Badge.find_by_id(params[:id])
    if (!badge.present?)
      render json: {
        message: "Badge not found"
      }, status: 401 and return
    end
    issuer = "#{api_openbadges_issuer_organization_index_url}.json"
    render json: BackpackConnect::Assertions::BadgeClass.new(badge, issuer, request.host_with_port)
  end
end
