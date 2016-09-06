class BadgesController < ApplicationController
  include SortsPosition

  before_filter :ensure_staff?, except: [:index, :show]
  before_action :find_badge, only: [:show, :edit, :update, :destroy]

  # GET /badges
  def index
    render Badges::IndexPresenter.build({
      title: term_for(:badges),
      badges: current_course.badges,
      student: current_student
    })
  end

  # GET /badges/:id
  def show
    render Badges::ShowPresenter.build({
      course: current_course,
      badge: @badge,
      student: current_student,
      teams: current_course.teams,
      params: params
    })
  end

  def new
    @title = "Create a New #{term_for :badge}"
    @badge = current_course.badges.new
  end

  def edit
    @title = "Editing #{@badge.name}"
  end

  def create
    @badge = current_course.badges.new(badge_params)

    if @badge.save
      respond_with @badge
    else
      render action: "new"
    end
  end

  def update
    if @badge.update_attributes(badge_params)
      respond_with @badge
    else
      render action: "edit"
    end
  end

  def sort
    sort_position_for :badge
  end

  def destroy
    @name = @badge.name
    @badge.destroy
    respond_with @badge
  end
  
  def export_structure
    course = current_user.courses.find_by(id: params[:id])
    respond_to do |format|
      format.csv { send_data BadgeExporter.new.export(course), filename: "#{ course.name } #{ (term_for :badges).titleize } - #{ Date.today }.csv" }
    end
  end

  private

  def badge_params
    params.require(:badge).permit(:name, :description, :icon, :visible, :full_points,
      :can_earn_multiple_times, :earned_badges, :earned_badges_attributes,
      :badge_file_ids, :badge_files_attributes, :badge_file, :position,
      :visible_when_locked, :course_id, :course, :show_name_when_locked,
      :show_points_when_locked, :show_description_when_locked,
      unlock_conditions_attributes: [:id, :unlockable_id, :unlockable_type, :condition_id,
        :condition_type, :condition_state, :condition_value, :condition_date, :_destroy],
      badge_files_attributes: [:id, file: []])
  end

  def find_badge
    @badge = current_course.badges.find(params[:id])
  end
  
  def flash_interpolation_options
    { resource_name: @badge.name }
  end
end
