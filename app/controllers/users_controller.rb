require_relative "../services/cancels_course_membership"
require_relative "../services/creates_or_updates_user"

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
      # TODO: should show TAs as well
      @users = @team.students
    else
      @users = current_course.users.includes(:courses, :teams)
    end
    respond_to do |format|
      format.html
      format.csv { send_data @users.to_csv }
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
    result = Services::CreatesOrUpdatesUser.create_or_update params[:user], current_course,
      params[:send_welcome] == "1"
    @user = result[:user]

    if result.success?
      if @user.is_student?(current_course)
        redirect_to students_path,
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
    @user.assign_attributes params[:user]
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
      format.html {
        redirect_to users_url,
        notice: "#{@name} was successfully deleted"
      }
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

    if @user.update_attributes params[:user]
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
    @title = "Edit My Profile"
    @user = current_user
    @course_membership =
      @user.course_memberships.where(course_id: current_course).first
  end

  def update_profile
    @user = current_user

    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update_attributes(params[:user])
      redirect_to dashboard_path,
        notice: "Your profile was successfully updated!"
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
end
