class AddThresholdPointsToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :threshold_points, :integer, default: 0
  end
end


