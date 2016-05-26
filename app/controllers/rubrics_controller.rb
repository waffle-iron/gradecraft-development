class RubricsController < ApplicationController
  before_filter :ensure_staff?

  before_action :find_rubric, except: [:design, :create, :export]

  respond_to :html, :json

  def design
    @assignment = current_course.assignments.find params[:assignment_id]
    @rubric = @assignment.fetch_or_create_rubric
    @course_badge_count = @assignment.course.badges.visible.count
    @title = "Design Rubric for #{@assignment.name}"
    respond_with @rubric
  end

  def create
    @rubric = Rubric.create params[:rubric]
    respond_with @rubric
  end

  def destroy
    @rubric.destroy
    respond_with @rubric
  end

  def update
    @rubric.update_attributes params[:rubric]
    respond_with @rubric, status: :not_found
  end

  def export
    assignment = current_course.assignments.find params[:assignment_id]
    rubric = assignment.rubric
    respond_to do |format|
      format.csv { send_data RubricExporter.new.export(rubric), filename: "#{assignment.name} Rubric.csv" }
    end
  end

  private

  def find_rubric
    @rubric = @assignment.rubric
  end
end
