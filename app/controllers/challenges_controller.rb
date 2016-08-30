class ChallengesController < ApplicationController

  before_filter :ensure_staff?,
    except: [:index, :show, :predictor_data, :predict_points]
  before_filter :ensure_student?, only: [:predict_points]
  before_action :find_challenge, only: [:show, :edit, :update, :destroy]

  def index
    @title = "#{term_for :challenges}"
    @challenges = current_course.challenges
  end

  def show
    @title = @challenge.name
    @teams = current_course.teams
  end

  def new
    @challenge = current_course.challenges.new
    @title = "Create a New #{term_for :challenge}"
  end

  def edit
    @title = "Editing #{@challenge.name}"
  end

  def create
    @challenge = current_course.challenges.create(challenge_params)

    if @challenge.save
      redirect_to @challenge
      flash[:success] = "Challenge #{@challenge.name} successfully created"
    else
      render action: "new"
    end
  end

  def update
    if @challenge.update_attributes(challenge_params)
      redirect_to challenges_path
      flash[:success] = "Challenge #{@challenge.name} successfully updated"
    else
      render action: "edit"
    end
  end

  def destroy
    @name = "#{@challenge.name}"
    @challenge.destroy
    flash[:success] = "Challenge #{@name} successfully deleted"
    redirect_to challenges_path
  end

  private

  def challenge_params
    params.require(:challenge).permit :name, :description, :visible, :full_points,
      :due_at, :open_at, :accepts_submissions, :release_necessary,
      :course, :team, :challenge, :challenge_file_ids,
      :challenge_files_attributes, :challenge_file, :challenge_grades_attributes, :challenge_score_level,
      challenge_score_levels_attributes: [:id, :name, :points, :_destroy],
      challenge_files_attributes: [:id, file: []]
  end

  def find_challenge
    @challenge = current_course.challenges.includes(:challenge_score_levels).find(params[:id])
  end
end
