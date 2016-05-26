class LTIErrorPreview
  def lti_error
    user = User.first
    course = Course.first
    NotificationMailer.lti_error user, course
  end
end
