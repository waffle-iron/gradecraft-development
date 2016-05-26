class AddExpectationToLevels < ActiveRecord::Migration
  def up
    add_column :levels, :meets_expectations, :boolean, default: false
    add_column :criteria, :meets_exptecations_level_id, :integer
    add_column :criteria, :meets_expectations_points, :integer, default: 0
    change_column :levels, :full_credit, :boolean, default: false
    change_column :levels, :no_credit, :boolean, default: false
    remove_column :levels, :durable, :boolean
  end

  def down
    remove_column :levels, :meets_expectations, :boolean, default: false
    change_column :levels, :full_credit, :boolean, default: nil
    change_column :levels, :no_credit, :boolean, default: nil
    add_column :levels, :durable, :boolean
  end
end
