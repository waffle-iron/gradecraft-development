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
    @announcement = Announcement.new(announcement_params
      .merge(course_id: current_course.id, author_id: current_user.id))
    authorize! :create, @announcement
    if @announcement.save
      @announcement.deliver!
      flash[:success] = "Announcement created and sent."
      redirect_to announcements_path
    else 
      @title = "Create a New Announcement"
      render :new
    end
  end

  private

  def announcement_params
    params.require(:announcement).permit(:author_id, :body, :course_id, :title)
  end
end
