class BadgesController < ApplicationController
  include SortsPosition

  before_filter :ensure_staff?
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
    @badge = current_course.badges.new(params[:badge])

    if @badge.save
      redirect_to @badge,
        notice: "#{@badge.name} #{term_for :badge} successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @badge.update_attributes(params[:badge])
      redirect_to badges_path,
        notice: "#{@badge.name} #{term_for :badge} successfully updated"
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
    redirect_to badges_path,
      notice: "#{@name} #{term_for :badge} successfully deleted"
  end

  private

  def find_badge
    @badge = current_course.badges.find(params[:id])
  end
end
