require_relative "../services/cancels_course_membership"
require_relative "../services/creates_or_updates_user"

class UsersController < ApplicationController
  include UsersHelper

  respond_to :html, :json

  before_action :ensure_staff?,
    except: [:activate, :activated, :edit_profile, :update_profile]
  before_action :ensure_admin?, only: [:all]
  skip_before_action :require_login, only: [:activate, :activated]

  def index
    @teams = current_course.teams
    @team = @teams.find_by(id: params[:team_id]) if params[:team_id]
    if params[:team_id].present?
      @users = @team.students
      @users << @team.leaders
    else
      @users = current_course.users.includes(:courses, :teams).order_by_name
    end
  end

  def new
    @user = User.new
    CourseMembershipBuilder.new(current_user).build_for(@user)
  end

  def edit
    @user = User.find(params[:id])
    CourseMembershipBuilder.new(current_user).build_for(@user)
  end

  def create
    result = Services::CreatesOrUpdatesUser.create_or_update user_params, current_course,
      params[:send_welcome] == "1"
    @user = result[:user]

    if result.success?
      if @user.is_student?(current_course)
        redirect_to students_path,
          # rubocop:disable AndOr
          notice: "#{term_for :student} #{@user.name} was successfully created!" and return
      elsif @user.is_staff?(current_course)
        redirect_to staff_index_path,
          notice: "Staff Member #{@user.name} was successfully created!" and return
      end
    end

    CourseMembershipBuilder.new(current_user).build_for(@user)
    render :new
  end

  def update
    @user = User.find(params[:id])
    @user.assign_attributes user_params
    cancel_course_memberships @user
    if @user.save
      if @user.is_student?(current_course)
        redirect_to students_path, notice: "#{term_for :student} #{@user.name} was successfully updated!" and return
      elsif @user.is_staff?(current_course)
        redirect_to staff_index_path, notice: "Staff Member #{@user.name} was successfully updated!" and return
      end
    end

    CourseMembershipBuilder.new(current_user).build_for(@user)
    render :edit
  end

  def destroy
    @user = current_course.users.find(params[:id])
    @name = @user.name
    @user.destroy

    respond_to do |format|
      format.html do
        redirect_to users_url,
        notice: "#{@name} was successfully deleted"
      end
    end
  end

  def activate
    @user = User.load_from_activation_token(params[:id])
    @token = params[:id]
    redirect_to root_path, alert: "Invalid activation token. Please contact support to request a new one." and return unless @user
  end

  def activated
    @token = params[:token]
    @user = User.load_from_activation_token(@token)

    redirect_to root_path, alert: "Invalid activation token. Please contact support to request a new one." and return unless @user

    if @user.update_attributes user_params
      @user.activate!
      auto_login @user
      redirect_to dashboard_path, notice: "Welcome to GradeCraft!" and return
    end
    render :activate, alert: @user.errors.full_messages.first
  end

  def flag
    @user = User.find(params[:id])
    FlaggedUser.toggle! current_course, current_user, @user.id
  end

  # We don't allow students to edit their info directly
  def edit_profile
    @user = current_user
    @course_membership =
      @user.course_memberships.where(course_id: current_course).first
  end

  def update_profile
    @user = current_user

    up = user_params
    if up[:password].blank? && up[:password_confirmation].blank?
      up.delete(:password)
      up.delete(:password_confirmation)
    end

    if @user.update_attributes(up)
      redirect_to dashboard_path,
        notice: "Your profile was successfully updated!"
    else
      @course_membership =
        @user.course_memberships.where(course_id: current_course).first
      render :edit_profile
    end
  end

  def import
  end

  # import users for class
  def upload
    if params[:file].blank?
      flash[:notice] = "File missing"
      redirect_to users_path
    else
      @result = CSVStudentImporter.new(params[:file].tempfile,
                                       params[:internal_students] == "1",
                                       params[:send_welcome] == "1")
        .import(current_course)
      render :import_results
    end
  end

  private

  def user_params
    params.require(:user).permit :username, :email, :admin, :password, :time_zone, :password_confirmation, :activation_token_expires_at, :activation_token,
      :activation_state, :avatar_file_name, :first_name, :last_name, :user_id,
      :kerberos_uid, :display_name, :current_course_id, :last_activity_at, :reset_password_email_sent_at, :reset_password_token_expires_at, :reset_password_token,
      :last_login_at, :last_logout_at, :team_ids, :course_ids, :remember_me_token_expires_at,
      :remember_me_token, :team_role, :team_id, :lti_uid, :course_team_ids, :internal,
      earned_badges_attributes: [:points, :feedback, :student_id, :badge_id,
        :submission_id, :course_id, :assignment_id, :level_id, :criterion_id, :grade_id,
        :student_visible, :id, :_destroy],
      course_memberships_attributes: [:auditing, :character_profile, :course_id,
        :instructor_of_record, :user_id, :role, :last_login_at, :id, :_destroy]
  end
end
