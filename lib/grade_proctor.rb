require_relative "grade_proctor/base"
require_relative "grade_proctor/updatable"
require_relative "grade_proctor/viewable"

# determines what sort of CRUD operations can be performed
# on a `Grade` resource
class GradeProctor
  include Updatable
  include Viewable

  attr_reader :grade

  def initialize(grade)
    @grade = grade
  end

  def destroyable?(options={})
    updatable? options
  end
end
