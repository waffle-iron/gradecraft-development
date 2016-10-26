class RenameSubmissionsExportStudentIds < ActiveRecord::Migration
  def up
    rename_column :submissions_exports, :student_ids, :submitter_ids
    remove_column :submissions_exports, :group_ids
  end

  def down
    rename_column :submissions_exports, :submitter_ids, :student_ids
    add_column :submissions_exports, :group_ids, :integer, null: false, array: true, default: []
  end
end
