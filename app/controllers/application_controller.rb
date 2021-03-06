require "application_responder"
require "lull"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder

  include Omniauth::Lti::Context
  include Croutons::Controller
  include CustomNamedRoutes
  include CurrentScopes
  include CourseTerms
  include ZipUtils

  respond_to :html

  protect_from_forgery with: :null_session

  Rails.env.production? do
    before_action :check_url
  end

  def check_url
    redirect_to request.protocol + "www." + request.host_with_port +
      request.fullpath if !/^www/.match(request.host)
  end

  before_action :require_login, except: [:not_authenticated]
  before_action :increment_page_views
  before_action :course_scores
  before_action :set_paper_trail_whodunnit

  include ApplicationHelper

  def not_authenticated
    if !request.env["REMOTE_USER"].nil?
      @user = User.find_by_username(request.env["REMOTE_USER"])
      if @user
        auto_login(@user)
        redirect_to dashboard_path
      else
        redirect_to root_url, alert: "Please login first."
        # TODO: We ultimately need to handle Cosign approved users who don't
        # have GradeCraft accounts
      end
    else
      redirect_to root_path, alert: "Please login first."
    end
  end

  # Getting the course scores to display the box plot results
  def course_scores
    if current_user.present? && current_student.present?
      @scores_for_current_course =
        current_student.scores_for_course(current_course)
    end
  end

  def redirect_back_or_default(path=root_path, options={})
    if request.env["HTTP_REFERER"].present? &&
       request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      redirect_back(fallback_location: path)
    else
      redirect_to path, options
    end
  end

  # Tracking course logins
  def record_course_login_event(event_options = {})
    return unless request.format.html? || request.format.xml?
    event_attrs = event_session.merge event_options
    return unless [:course, :user].all? { |attr| event_attrs[attr].present? }
    current_user.course_memberships.where(course: current_course).first.last_login_at = Time.now
    LoginEventLogger.new(event_attrs).enqueue_with_fallback
  end

  # Session data used for building attributes hashes in EventLogger classes
  def event_session
    {
      course: current_course,
      user: current_user,
      student: current_student,
      request: request
    }
  end

  protected

  # Core role authentication
  def ensure_student?
    return not_authenticated unless current_user_is_student?
  end

  def ensure_staff?
    return not_authenticated unless current_user_is_staff?
  end

  def ensure_not_impersonating?
    redirect_to root_path unless !student_impersonation?
  end

  def ensure_prof?
    return not_authenticated unless current_user_is_professor?
  end

  def ensure_admin?
    return not_authenticated unless current_user_is_admin?
  end

  def save_referer
    session[:return_to] = request.referer
  end

  private

  def current_ability
    @current_ability ||= Ability.new(current_user, current_course)
  end

  # Tracking page view counts
  def increment_page_views
    return unless current_user && request.format.html?
    PageviewEventLogger.new(event_session)
                       .enqueue_in_with_fallback Lull.time_until_next_lull
  end
end
