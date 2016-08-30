class PasswordsController < ApplicationController
  skip_before_filter :require_login

  def new
  end

  def create
    @user = User.find_by_insensitive_email(params[:email])
    @user.deliver_reset_password_instructions! if @user
    
    flash[:success] = "Password reset instructions have been sent to your email."
    redirect_to root_path
  end

  def edit
    @user = User.load_from_reset_password_token(params[:id])
    @token = params[:id]
    flash[:alert] = "Invalid or expired password reset token. Please request new password reset instructions."
    redirect_to new_password_path
  end

  def update
    @token = params[:token]
    @user = User.load_from_reset_password_token(@token)
    
    flash[:alert] = "Invalid or expired password reset token. Please request new password reset instructions."
    redirect_to new_password_path

    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.change_password!(params[:user][:password])
      @user.activate! unless @user.activated?
      auto_login @user
      flash[:success] = "Password was successfully updated"
      redirect_to dashboard_path
    end
    render :edit
    flash[:alert] = @user.errors.full_messages.first
  end
end
