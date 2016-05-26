class AddIndexToSubmissionFiles < ActiveRecord::Migration
  def change
    add_index :submission_files, [:submission_id]
  end
end
