class EventsController < ApplicationController

  respond_to :html, :json

  before_filter :ensure_staff?, except: [:show, :index]

  def index
    @events = current_course.events.order("due_at ASC")
    @title = "Calendar Events"
  end

  def show
    @event = current_course.events.find(params[:id])
    @title = @event.name
  end

  def new
    @event = current_course.events.new
    @title = "Create a New Calendar Event"
  end

  def edit
    @event = current_course.events.find(params[:id])
    @title = "Editing #{@event.name}"
  end

  def create
    @event = current_course.events.new(event_params)
    if @event.save
      flash[:success] = "Event #{@event.name} was successfully created"
      respond_with(@event)
    else
      @title = "Create a New Calendar Event"
      render :new
    end
  end

  def update
    @event = current_course.events.find(params[:id])
    flash[:success] = "Event #{@event.name} was successfully updated" if @event.update(event_params)
    respond_with(@event)
  end

  def destroy
    @event = current_course.events.find(params[:id])
    @name = @event.name
    @event.destroy
    flash[:success] = "#{@name} successfully deleted"
    redirect_to events_url
  end

  private

  def event_params
    params.require(:event).permit(:course_id, :name, :description, :open_at, 
    :due_at, :media, :thumbnail, :media_credit, :media_caption)
  end
end
