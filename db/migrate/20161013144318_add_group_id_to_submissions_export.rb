class AddGroupIdToSubmissionsExport < ActiveRecord::Migration
  def change
    add_column :submissions_exports, :group_id, :integer
  end
end
