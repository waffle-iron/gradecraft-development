class ChallengeGradesController < ApplicationController

  before_filter :ensure_staff?, except: [:show]
  before_action :find_challenge,
    only: [:index, :create, :show, :new, :edit, :mass_edit, :challenge,
    :update, :edit_status, :update_status, :destroy ]
  before_action :find_challenge_grade, only: [:show, :edit, :update, :destroy]

  def index
    redirect_to @challenge
  end

  def show
    @team = @challenge_grade.team
    @title = "#{@team.name}'s #{@challenge_grade.name} Grade"
  end

  def new
    @team = current_course.teams.find(params[:team_id])
    @challenge_grade = @team.challenge_grades.new
    @title = "Grading #{@team.name}'s #{@challenge.name}"
  end

  def edit
    @title = "Editing #{@challenge.name} Grade"
    @team = current_course.teams.find(params[:team_id])
  end

  # Grade many teams on a particular challenge at once
  def mass_edit
    @teams = current_course.teams
    @title = "Quick Grade #{@challenge.name}"
    @challenge_score_levels = @challenge.challenge_score_levels
    @challenge_grades = @teams.map do |t|
      @challenge.challenge_grades.where(team_id: t).first ||
        @challenge.challenge_grades.new(team: t, challenge: @challenge)
    end
  end

  def mass_update
    @challenge = current_course.challenges.find(params[:id])
    if @challenge.update_attributes(params[:challenge])
      redirect_to challenge_path(@challenge),
        notice: "#{@challenge.name} #{term_for :challenge} successfully graded"
    else
      render action: "mass_edit"
    end
  end

  # @mz TODO: refactor this whole thing, move into models and presenters
  def create
    @challenge_grade =
      @challenge.challenge_grades.create(params[:challenge_grade])
    @team = @challenge_grade.team
    respond_to do |format|
      if @challenge_grade.save
        if current_course.add_team_score_to_student? &&
          @challenge_grade.is_student_visible?
          # @mz TODO: substitute with ChallengeGrade#recalculate_team_scores
          # method, revise specs
          @score_recalculator_jobs = @team.students.collect do |student|
            ScoreRecalculatorJob.new(user_id: student.id,
              course_id: current_course.id)
          end
          @score_recalculator_jobs.each(&:enqueue)
        end
        format.html {
          redirect_to @challenge,
          notice: "#{@team.name}'s Grade for #{@challenge.name} #{(term_for :challenge).titleize} successfully graded"
        }
      else
        format.html { render action: "new" }
      end
    end
  end

  # @mz TODO: refactor this whole thing, move into models and presenters
  def update
    @team = @challenge_grade.team
    respond_to do |format|
      if @challenge_grade.update_attributes(params[:challenge_grade])

        if current_course.add_team_score_to_student?
          if student_grades_require_update?
            # @mz TODO: substitute with ChallengeGrade#recalculate_team_scores
            # method, revise specs
            # @mz TODO: figure out how @team.students is supposed to be sorted
            # in the controller
            @score_recalculator_jobs = @team.students.collect do |student|
              ScoreRecalculatorJob.new(user_id: student.id,
                course_id: current_course.id)
            end
            @score_recalculator_jobs.each(&:enqueue)
          end
        end

        format.html {
          redirect_to @challenge,
          notice: "#{@team.name}'s Grade for #{@challenge.name} #{(term_for :challenge).titleize} successfully updated"
        }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # Changing the status of a grade - allows instructors to review "Graded"
  # grades, before they are "Released" to students
  def edit_status
    @title = "#{@challenge.name} Grade Statuses"
    @challenge_grades =
      @challenge.challenge_grades.find(params[:challenge_grade_ids])
  end

  def update_status
    @challenge_grades =
      @challenge.challenge_grades.find(params[:challenge_grade_ids])
    @challenge_grades.each do |challenge_grade|
      challenge_grade.update_attributes!(params[:challenge_grade].reject { |k,v| v.blank? })
    end
    flash[:notice] = "Updated #{(term_for :challenge).titleize} Grades!"
    redirect_to challenge_path(@challenge)
  end

  def destroy
    @team = @challenge_grade.team

    @challenge_grade.destroy
    @challenge_grade.recalculate_student_and_team_scores

    redirect_to challenge_path(@challenge),
      notice: "#{@team.name}'s grade for #{@challenge.name} has been successfully deleted."
  end

  # @mz TODO: refactor all of this nonsense, add specs etc, this works for now
  private

  def student_grades_require_update?
    score_update_required? || visibility_update_required?
  end

  def score_update_required?
    score_changed? && @challenge_grade.is_student_visible?
  end

  def visibility_update_required?
    visibility_changed? && @challenge_grade.is_student_visible?
  end

  def visibility_changed?
    @challenge_grade.previous_changes[:status].present?
  end

  def score_changed?
    @challenge_grade.previous_changes[:score].present?
  end

  def find_challenge
    @challenge = current_course.challenges.find(params[:challenge_id])
  end

  def find_challenge_grade
    @challenge_grade = @challenge.challenge_grades.find(params[:id])
  end
end
