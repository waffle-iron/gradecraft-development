
class API::LevelsController < ApplicationController
  before_filter :ensure_staff?

  # PUT api/level/:id
  def update
    level = Level.find(params[:id])

    if params[:level].key? :meets_expectations
      level.criterion.update_meets_expectations!(
        level, params[:level][:meets_expectations]
      )
    end

    if level.update_attributes(level_params)
      render json: { message: "level successfully updated", success: true }
    else
      render json: {
        errors: [{ detail: "failed to update level" }], success: false
        },
        status: 500
    end
  end

  private

  def updating_meets_expectations?
    params[:level][:meets_expectations] == true
  end

  def level_params
    params.require(:level).permit(:name, :description)
  end
end


