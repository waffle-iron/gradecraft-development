class TeamsController < ApplicationController
  respond_to :html, :json

  before_filter :ensure_staff?, except: [:index]

  def index
    @teams = current_course.teams.order_by_rank.includes(:earned_badges)
    @title = "#{term_for :teams}"
    @team = current_student.team_for_course(current_course) if current_user_is_student?
  end

  def show
    @team = current_course.teams.find(params[:id])
    @students = @team.students
    @challenges = current_course.challenges.chronological.alphabetical
    @title = @team.name
  end

  def new
    @team =  current_course.teams.new
    @title = "Create a New #{term_for :team}"
    @submit_message = "Create #{term_for :team}"
  end

  def create
    @team =  current_course.teams.new(team_params)
    @team.save
    @team.team_memberships.build
    flash[:success] = "Team #{@team.name} successfully created"
    redirect_to @team
  end

  def edit
    @team =  current_course.teams.find(params[:id])
    @title = "Editing #{@team.name}"
    @submit_message = "Update #{term_for :team}"
  end

  def update
    @team = current_course.teams.find(params[:id])
    @team.update_attributes(team_params)
    flash[:success] = "Team #{@team.name} successfully updated"
    redirect_to @team 
  end

  def destroy
    @team = current_course.teams.find(params[:id])
    @name = "#{@team.name}"
    @team.destroy
    flash[:success] = "#{(term_for :team).titleize} #{@name} successfully deleted"
    redirect_to teams_url
  end

  private

  def team_params
    params.require(:team).permit :name, :course, :course_id, :average_score,
      :banner, :rank, :challenge_grade_score, student_ids: [], leader_ids: [],
      team_memberships_attributes: [:id, :student_id, :team_id, :_destroy],
      team_leaderships_attributes: [:id, :leader_id, :team_id, :_destroy]
  end
end
