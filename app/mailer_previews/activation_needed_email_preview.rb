class ActivationNeededEmailPreview
  def activation_needed_email
    user = User.last
    # arbitrary value for testing purposes
    user.activation_token = 102
    UserMailer.activation_needed_email user
  end
end
