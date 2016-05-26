require 'application_responder'

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder

  include Omniauth::Lti::Context
  include CustomNamedRoutes
  include CurrentScopes
  include CourseTerms
  include ZipUtils

  respond_to :html

  protect_from_forgery with: :null_session

  Rails.env.production? do
    before_filter :check_url
  end

  def check_url
    redirect_to request.protocol + "www." + request.host_with_port +
      request.fullpath if !/^www/.match(request.host)
  end

  before_filter :require_login, except: [:not_authenticated]
  before_filter :increment_page_views
  before_filter :get_course_scores

  include ApplicationHelper

  def not_authenticated
    if !request.env["REMOTE_USER"].nil?
      @user = User.find_by_username(request.env["REMOTE_USER"])
      if @user
        auto_login(@user)
        User.increment_counter(:visit_count, @user.id)
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
  def get_course_scores
    if current_user.present? && current_student.present?
      @scores_for_current_course =
        current_student.scores_for_course(current_course)
    end
  end

  def redirect_back_or_default(path=root_path, options={})
    if request.env["HTTP_REFERER"].present? &&
       request.env["HTTP_REFERER"] != request.env["REQUEST_URI"]
      redirect_to :back
    else
      redirect_to path, options
    end
  end

  # Tracking course logins
  def record_course_login_event(event_options = {})
    return unless request.format.html? || request.format.xml?
    event_attrs = event_session.merge event_options
    return unless [:course, :user].all? { |attr| event_attrs[attr].present? }
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

  def ensure_prof?
    return not_authenticated unless current_user_is_professor?
  end

  def ensure_admin?
    return not_authenticated unless current_user_is_admin?
  end

  # To use: First create the temp directory you will be generating files in.
  # A copy of the directory will be created as a zip download, and the tempdir
  # will be deleted.
  #
  # example:
  #   export_dir = Dir.mktmpdir
  #   export_zip "my_zip", export_dir do
  #     open( "#{export_dir}/my_file.txt",'w' ) do |f|
  #       f.puts ...
  #     end
  #   end
  #
  def export_zip(export_name, temp_dir, &file_creation)
    begin
      file_creation.call
      zip_data = ZipUtils::Zip.new(temp_dir)
      send_data(zip_data.zipstring, type: "application/zip",
        filename: "#{export_name}.zip")
    ensure
      FileUtils.remove_entry_secure temp_dir
    end
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
