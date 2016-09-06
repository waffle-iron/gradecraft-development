require_relative "../services/cancels_course_membership"
require_relative "../services/creates_or_updates_user"

# rubocop:disable AndOr
class UsersController < ApplicationController
  include UsersHelper

  respond_to :html, :json

  before_filter :ensure_staff?,
    except: [:activate, :activated, :edit_profile, :update_profile]
  before_filter :ensure_admin?, only: [:all]
  skip_before_filter :require_login, only: [:activate, :activated]

  def index
    @title = "All Users"
    @teams = current_course.teams
    @team = @teams.find_by(id: params[:team_id]) if params[:team_id]
    if params[:team_id].present?
      @users = @team.students
      @users << @team.leaders
    else
      @users = current_course.users.includes(:courses, :teams)
    end
  end

  def new
    @title = "Create a New User"
    @user = User.new
    CourseMembershipBuilder.new(current_user).build_for(@user)
  end

  def edit
    @user = User.find(params[:id])
    @title = "Editing #{@user.name}"
    CourseMembershipBuilder.new(current_user).build_for(@user)
  end

  def create
    result = Services::CreatesOrUpdatesUser.create_or_update user_params, current_course,
      params[:send_welcome] == "1"
    @user = result[:user]

    if result.success?
      if @user.is_student?(current_course)
        respond_with @user, location: -> { students_path }
      elsif @user.is_staff?(current_course)
        respond_with @user, location: -> { staff_path }
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
        respond_with @user, location: -> { students_path }
      elsif @user.is_staff?(current_course)
        respond_with @user, location: -> { staff_path }
      end
    end
    
    CourseMembershipBuilder.new(current_user).build_for(@user)
    render :edit
  end

  def destroy
    @user = current_course.users.find(params[:id])
    @name = @user.name
    @user.destroy
    respond_with @user
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
      flash[:success] = "Welcome to GradeCraft!"
      redirect_to dashboard_path
    else
      render :activate, alert: @user.errors.full_messages.first
    end
  end

  def flag
    @user = User.find(params[:id])
    FlaggedUser.toggle! current_course, current_user, @user.id
  end

  # We don't allow students to edit their info directly
  def edit_profile
    @title = "Edit My Profile"
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
      respond_with @user, location: -> { dashboard_path }
    else
      @title = "Edit My Profile"
      @course_membership =
        @user.course_memberships.where(course_id: current_course).first
      render :edit_profile
    end
  end

  def import
    @title = "Import Users"
  end

  # import users for class
  def upload
    if params[:file].blank?
      flash[:notice] = "File missing"
      redirect_to users_path
    else
      @result = StudentImporter.new(params[:file].tempfile,
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
        :instructor_of_record, :user_id, :role, :last_login_at, :id, :_destroy],
      student_academic_history_attributes: [:student_id, :major, :gpa,
        :current_term_credits, :accumulated_credits, :year_in_school, :state_of_residence,
        :high_school, :athlete, :act_score, :sat_score, :course_id, :id, :_destroy]
  end
end
