require_relative "../services/creates_earned_badge"

class EarnedBadgesController < ApplicationController
  # Earned badges are to badges what grades are to assignments - the record of
  # how what and how a student performed

  skip_before_filter :require_login, only: [:confirm_earned]
  before_filter :ensure_staff?, except: [:confirm_earned]
  before_action :find_badge, except: [:confirm_earned]
  before_action :find_earned_badge, only: [:show, :edit, :update, :destroy ]

  def index
    redirect_to badge_path(@badge)
  end

  def show
    @student = @earned_badge.student
    @title = "#{@student.name}'s #{@badge.name} #{term_for :badge}"
  end

  def confirm_earned
    @course = Course.find(params[:course_id])
    @badge = @course.badges.find(params[:badge_id])
    @earned_badge = @badge.earned_badges.where(id: params[:id]).first
    if @earned_badge.present?
      render nothing: true, status: 200
    else 
      redirect_to root_path
    end
  end

  def new
    @title = "Award #{@badge.name}"
    @earned_badge = @badge.earned_badges.new
    @students = current_course.students
  end

  def edit
    @students = current_course.students
    @title = "Editing Awarded #{@badge.name}"
  end

  def create
    result = Services::CreatesEarnedBadge.award earned_badge_params

    if result.success?
      respond_with result.earned_badge, location: -> { badge_path(@badge) }
    else
      @title = "Award #{@badge.name}"
      @earned_badge = result.earned_badge
      @students = current_course.students
      render action: "new"
    end
  end

  def update
    if @earned_badge.update_attributes(earned_badge_params)
      if @badge.full_points?
        ScoreRecalculatorJob.new(user_id: @earned_badge.student_id,
                                 course_id: current_course.id).enqueue
      end
      expire_fragment "earned_badges"
      respond_with @earned_badge, location: -> { badge_path(@badge) }
    else
      render action: "edit"
    end
  end

  # Quickly award a badge to multiple students
  def mass_edit
    @title = "Quick Award #{@badge.name}"
    @teams = current_course.teams

    if params[:team_id].present?
      @team = current_course.teams.find params[:team_id]
      @students = current_course.students_by_team(@team)
    else
      @students = current_course.students
    end

    # build a new badge automatically if they can be earned at will
    if @badge.can_earn_multiple_times?
      @earned_badges = @students.map do |student|
        @badge.earned_badges.new(student: student, badge: @badge)
      end
    # otherwise build a new one only if it hasn't been earned
    else
      @earned_badges = @students.map do |student|
        @badge.earned_badges.where(student_id: student).first ||
          @badge.earned_badges.new(student: student, badge: @badge)
      end
    end
  end

  def mass_earn
    @valid_earned_badges ||= parse_valid_earned_badges
    make_badges_student_visible
    send_earned_badge_notifications
    if @badge.full_points?
      update_student_point_totals
    end
    handle_mass_update_redirect
  end

  def destroy
    @name = "#{@badge.name}"
    @student_name = "#{@earned_badge.student.name}"
    @earned_badge.destroy
    expire_fragment "earned_badges"
    respond_with @badge
  end

  private

  def earned_badge_params
    params.require(:earned_badge).permit :points, :feedback, :student_id, :badge_id,
      :submission_id, :course_id, :assignment_id, :level_id, :criterion_id, :grade_id,
      :student_visible, :_destroy
  end

  def find_badge
    @badge = current_course.badges.find(params[:badge_id])
  end

  def find_earned_badge
    @earned_badge = @badge.earned_badges.find(params[:id])
  end

  def parse_valid_earned_badges
    params[:student_ids].inject([]) do |valid_earned_badges, student_id|
      earned_badge = EarnedBadge.create(student_id: student_id, badge: @badge)
      if earned_badge.valid?
        valid_earned_badges << earned_badge
      else
        logger.error earned_badge.errors.full_messages
      end
      valid_earned_badges
    end
  end

  def make_badges_student_visible
    @valid_earned_badges.each do |earned_badge|
      earned_badge.student_visible = true
      earned_badge.save
    end
  end

  def update_student_point_totals
    @valid_earned_badges.each do |earned_badge|
      ScoreRecalculatorJob.new(user_id: earned_badge.student.id,
        course_id: current_course.id).enqueue
      logger.info "Updated student scores to include EarnedBadge ##{earned_badge[:id]}"
    end
  end

  def send_earned_badge_notifications
    @valid_earned_badges.each do |earned_badge|
      NotificationMailer.earned_badge_awarded(earned_badge.id).deliver_now
      logger.info "Sent an earned badge notification for EarnedBadge ##{earned_badge[:id]}"
    end
  end

  def handle_mass_update_redirect
    if @valid_earned_badges.any?
      flash[:success] = "The #{@badge.name} #{term_for :badge} was successfully awarded #{@valid_earned_badges.count} times"
      redirect_to badge_path(@badge)
    else
      flash[:alert] = "No earned badges were sucessfully created."
      redirect_to mass_edit_badge_earned_badges_path(@badge)
    end
  end
end
