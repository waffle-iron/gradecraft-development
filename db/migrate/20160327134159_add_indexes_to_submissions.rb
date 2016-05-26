class AddIndexesToSubmissions < ActiveRecord::Migration
  def change
    add_index :submissions, [:assignment_id, :student_id]
    add_index :submissions, [:assignment_id, :group_id]
    add_index :submissions, [:assignment_id]
    add_index :submissions, [:assignment_type_id]
  end
end
