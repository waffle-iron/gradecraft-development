class AddUnlockStateMigration < ActiveRecord::Migration
  def change
    add_index :unlock_states, [:unlockable_id, :unlockable_type]
  end
end
