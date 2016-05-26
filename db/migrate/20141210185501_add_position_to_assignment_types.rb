class AddPositionToAssignmentTypes < ActiveRecord::Migration
  def change
  	add_column :assignment_types, :position, :integer
  end
end
