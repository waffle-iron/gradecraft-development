class UserSessionsController < ApplicationController

  skip_before_filter :require_login, except: [:index]
  skip_before_filter :verify_authenticity_token, only: [:lti_create]

  def new
    @user = User.new
  end

  # sorcery login - users have passwords stored in our db
  def create
    respond_to do |format|
      if @user = login(params[:user][:email], params[:user][:password])
        record_course_login_event user: @user
        format.html { redirect_back_or_to dashboard_path }
        format.xml { render xml: @user, status: :created, location: @user }
      else
        @user = User.new
        format.html {
          flash.now[:error] = "Email or Password were invalid, login failed.";
          render action: "new"
        }
        format.xml { render xml: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  # lti login - we do not record users passwords, they login via an outside app
  def lti_create
    @user = User.find_or_create_by_lti_auth_hash(auth_hash)
    @course = Course.find_or_create_by_lti_auth_hash(auth_hash)
    if !@user || !@course
      lti_error_notification
      flash[:alert] = t("sessions.create.error")
      redirect_to auth_failure_path
      return
    end
    @user.courses << @course unless @user.courses.include?(@course)
    @course_membership = @user.course_memberships.where(course_id: @course).first
    @course_membership.assign_role_from_lti(auth_hash) if @course_membership
    save_lti_context
    session[:course_id] = @course.id
    auto_login @user
    User.increment_counter(:visit_count, @user.id)
    respond_with @user, location: dashboard_path
  end

  def destroy
    logout
    redirect_to root_url, notice: "You are now logged out. Thanks for playing!"
  end

  private

  def auth_hash
    request.env["omniauth.auth"]
  end

  def lti_error_notification
    user = { name: auth_hash["extra"]["raw_info"]["lis_person_name_full"], email: auth_hash["extra"]["raw_info"]["lis_person_contact_email_primary"], lti_uid: auth_hash["extra"]["raw_info"]["context_id"] }
    course = { name: auth_hash["extra"]["raw_info"]["context_label"], uid: auth_hash["extra"]["raw_info"]["context_id"] }
    NotificationMailer.lti_error(user, course).deliver_now
  end

  def redirect_back_or(default)
    redirect_to(session[:return_to] || default)
    clear_return_to
  end
end
