class TeamsController < ApplicationController
  respond_to :html, :json

  before_filter :ensure_staff?

  def index
    @teams = current_course.teams.order_by_high_score.includes(:earned_badges)
    @title = "#{term_for :teams}"
  end

  def show
    @team = current_course.teams.find(params[:id])
    @students = @team.students
    @challenges = current_course.challenges.chronological.alphabetical
    @title = @team.name
  end

  def new
    @team =  current_course.teams.new
    @team_memberships = @team.team_memberships.new
    @title = "Create a New #{term_for :team}"
    @course = current_course
    @users = current_course.users
    @team.team_memberships.build
    @students = current_course.students
    @submit_message = "Create #{term_for :team}"
    respond_with @team
  end

  def create
    @team =  current_course.teams.new(params[:team])
    @team.save
    @team.team_memberships.build
    respond_with @team, notice: "Team #{@team.name} successfully created"
  end

  def edit
    @team =  current_course.teams.find(params[:id])
    @title = "Editing #{@team.name}"
    @users = current_course.users
    @students = current_course.students
    @submit_message = "Update #{term_for :team}"
  end

  def update
    @team = current_course.teams.find(params[:id])
    @team.update_attributes(params[:team])
    respond_with @team, notice: "Team #{@team.name} successfully updated"
  end

  def destroy
    @team = current_course.teams.find(params[:id])
    @name = "#{@team.name}"
    @team.destroy
    respond_to do |format|
      format.html { redirect_to teams_url,
        notice: "#{(term_for :team).titleize} #{@name} successfully deleted"
      }
    end
  end

end
