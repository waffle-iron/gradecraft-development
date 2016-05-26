class AddIndexesToUnlockStates < ActiveRecord::Migration
  def change
    add_index :unlock_states, [:student_id]
  end
end
