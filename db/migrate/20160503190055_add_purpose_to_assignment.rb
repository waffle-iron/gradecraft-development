class AddPurposeToAssignment < ActiveRecord::Migration
  def change
    add_column :assignments, :purpose, :text
    add_column :assignments, :show_purpose_when_locked, :boolean, default: true
  end
end
