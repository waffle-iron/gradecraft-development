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
    @challenge = current_course.challenges.create(params[:challenge])

    respond_to do |format|
      if @challenge.save
        format.html {
          redirect_to @challenge,
          notice: "Challenge #{@challenge.name} successfully created"
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  def update
    respond_to do |format|
      if @challenge.update_attributes(params[:challenge])
        format.html {
          redirect_to challenges_path,
          notice: "Challenge #{@challenge.name} successfully updated"
        }
      else
        format.html { render action: "edit" }
      end
    end
  end

  def destroy
    @name = "#{@challenge.name}"
    @challenge.destroy

    respond_to do |format|
      format.html {
        redirect_to challenges_path,
        notice: "Challenge #{@name} successfully deleted"
      }
    end
  end

  private

  def find_challenge
    @challenge = current_course.challenges.includes(:challenge_score_levels).find(params[:id])
  end
end
