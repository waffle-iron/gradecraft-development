class API::BackpackConnectController < ApplicationController
  before_filter :persist_params

  def connect
    render json: @backpack_connect_authenticator
  end

  def issue
    access_token = session[:backpack_connect_authenticator].access_token
    render status: 401, json: {
      message: "User has not granted permissions to export badges.",
    }.to_json unless access_token
    render json: "Success."
  end

  private

  def persist_params
    @backpack_connect_authenticator = BackpackConnectAuthenticator.new(
      error: params[:error],
      expires: params[:expires],
      api_root: params[:api_root],
      access_token: params[:access_token],
      refresh_token: params[:refresh_token]
    )
    session[:backpack_connect_authenticator] = @backpack_connect_authenticator
  end

  #todo
  def connect_params
    params.require(:backpack_connect).permit(:error, :expires, :api_root, :access_token, :refresh_token)
  end
end
