# The Grade Scheme Elements define the point thresholds earned at which students
# earn course wide levels and grades
class API::GradeSchemeElementsController < ApplicationController

  def index
    @grade_scheme_elements = current_course
                             .grade_scheme_elements
                             .order_by_high_range.select(
                               :id,
                               :low_range,
                               :letter,
                               :level)
    if @grade_scheme_elements.present?
      @total_points = (@grade_scheme_elements.first.low_range).to_i
    else
      @total_points = current_course.total_points
    end
  end
end
