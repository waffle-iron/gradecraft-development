require "backpack_connect"

class API::Openbadges::IssuerOrganizationController < ApplicationController
  #todo make this configurable for other organizations
  def index
    options = { name: "University of Michigan", url: "www.umich.edu" }
    render json: BackpackConnect::Assertions::IssuerOrganization.new(options)
  end
end
