class RenameMeetsExpectationsLevelId < ActiveRecord::Migration
  def change
    rename_column :criteria, :meets_exptecations_level_id,
      :meets_expectations_level_id
  end
end
