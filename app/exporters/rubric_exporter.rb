class RubricExporter
  def export(rubric)
    CSV.generate do |csv|
      csv << baseline_headers
      rubric.criteria.each do |criterion|
        csv << complete_criterion_data(criterion)
      end
    end
  end

  private

  def baseline_headers
    ["Criteria ID", "Criteria Description" ]
  end

  def complete_criterion_data(criterion)
    base_criterion_data(criterion) + level_data_for(criterion)
  end

  def base_criterion_data(criterion)
    [criterion.id, criterion.name]
  end

  def level_data_for(criterion)
    level_data = []
    # add the levels for the criteria
    criterion.levels.ordered.inject(level_data) do |memo, level|
      memo << "#{level.name} (#{level.points} points) #{level.description}"
    end
  end
end
