class ChangeGroupIdToGroupIds < ActiveRecord::Migration
  def up
    remove_column :submissions_exports, :group_id
    add_column :submissions_exports, :group_ids, :integer, default: [], null: false, array: true
  end

  def down
    remove_column :submissions_exports, :group_ids
    add_column :submissions_exports, :group_id, :integer
  end
end
