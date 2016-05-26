class ExistingLevelSerializer < ActiveModel::Serializer
  attributes :id, :name, :description, :points, :full_credit, :no_credit
  has_many :level_badges, serializer: ExistingLevelBadgeSerializer

  def level_badges
    object.level_badges.order("created_at ASC")
  end
end
