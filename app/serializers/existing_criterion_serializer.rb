class ExistingCriterionSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :max_points, :rubric_id, :order
  has_many :levels, serializer: ExistingLevelSerializer

  def levels
    object.levels.order("points ASC")
  end
end
