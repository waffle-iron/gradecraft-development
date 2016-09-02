class RemoveInstructorModifiedFromGrades < ActiveRecord::Migration
  def change
    remove_column :grades, :instructor_modified
  end
end
