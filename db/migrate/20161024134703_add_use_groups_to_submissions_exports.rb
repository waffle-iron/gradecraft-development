class AddUseGroupsToSubmissionsExports < ActiveRecord::Migration
  def change
    add_column :submissions_exports, :use_groups, :boolean, default: false
  end
end
