# Unlock Conditions are used to declare a sequence of assignments or badges
# that must be completed at different levels before something else can be
# done. Unlock States store whether or not a student has met the necessary
# conditions

class UnlockConditionsController < ApplicationController

  before_filter :ensure_staff?

  def create
    @unlock_condition =
      current_course.unlock_condition.new(params[:unlock_condition])
    @unlock_condition.save
  end

  def update
    @unlock_condition = current_course.unlock_conditions.find(params[:id])
    @unlock_condition.update_attributes(params[:unlock_condition])
    respond_with @unlock_condition
  end

  def destroy
    @unlock_condition = current_course.unlock_conditions.find(params[:id])
    @unlock_condition.destroy
  end

end
