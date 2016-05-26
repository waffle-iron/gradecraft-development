class AnnouncementsController < ApplicationController
  include AnnouncementsHelper

  def index
    @title = "Announcements"
    @announcements = Announcement.where(course_id: current_course.id)
  end

  def show
    @announcement = Announcement.find params[:id]
    authorize! :show, @announcement
    @announcement.mark_as_read! current_user
    Rails.cache.delete unread_cache_key(current_user, @announcement.course)
    @title = @announcement.title
  end

  def new
    @title = "Create a New Announcement"
    @announcement = Announcement.new course_id: current_course.id
    authorize! :create, @announcement
  end

  def create
    announcement_params = params[:announcement]
      .merge({ course_id: current_course.id, author_id: current_user.id })
    @announcement = Announcement.new announcement_params
    authorize! :create, @announcement
    if @announcement.save
      @announcement.deliver!
      redirect_to announcements_path,
        notice: "Announcement created and sent." and return
    end

    @title = "Create a New Announcement"
    render :new
  end
end
