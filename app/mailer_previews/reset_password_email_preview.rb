class ResetPasswordEmailPreview
  def reset_password_email
    user = User.last
    # arbitrary value for testing purposes
    user.reset_password_token = 101
    UserMailer.reset_password_email user
  end
end
