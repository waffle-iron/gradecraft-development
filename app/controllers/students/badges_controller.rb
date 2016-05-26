class Students::BadgesController < ApplicationController

  before_filter :ensure_staff?

  # GET /students/:id/badges
  # faculty view of student's badge index view
  def index
    render "badges/index", Badges::IndexPresenter.build({
      title: term_for(:badges),
      badges: current_course.badges,
      student: current_student
    })
  end

  # GET /students/:id/badges/:id
  # faculty view of student's badge show page
  def show
    render "badges/show", Badges::ShowPresenter.build({
      course: current_course,
      badge: current_course.badges.find(params[:id]),
      student: current_student,
      teams: current_course.teams,
      params: params
    })
  end
end
