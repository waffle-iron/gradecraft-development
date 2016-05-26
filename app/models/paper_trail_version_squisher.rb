class PaperTrailVersionSquisher
  attr_reader :model

  def initialize(model)
    @model = model
  end

  def squish!(timeout_in_milliseconds)
    if current_version && previous_version &&
        within_timeout?(timeout_in_milliseconds) && versions_match?
      squish_object
      squish_object_changes

      current_version.save

      previous_version.destroy!
    end
  end

  private

  def current_version
    @current_version ||= model.versions.order(:id).last
  end

  def previous_version
    @previous_version ||= model.versions.order(:id)[-2]
  end

  def squish_object_changes
    changeset = previous_version.changeset.merge current_version.changeset
    current_version.object_changes = PaperTrail.serializer.dump(changeset)
  end

  def squish_object
    current = PaperTrail.serializer.load(current_version.object)
    current_version.changeset.each do |attribute, changes|
      current[attribute] = changes.last
    end
    current_version.object = PaperTrail.serializer.dump(current)
  end

  def versions_match?
    previous_version.event == current_version.event &&
      previous_version.whodunnit == current_version.whodunnit
  end

  def within_timeout?(timeout_in_milliseconds)
    ((Time.now.utc - current_version.created_at) / 60).abs <
      timeout_in_milliseconds
  end
end
