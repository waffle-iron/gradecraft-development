class LevelBadgesController< ApplicationController
  before_filter :ensure_staff?

  before_action :find_level_badge, only: [:update, :destroy]

  respond_to :json

  def create
    @level_badge = LevelBadge.create params[:level_badge]
    respond_with @level_badge, layout: false,
      serializer: ExistingLevelBadgeSerializer
  end

  def destroy
    @level_badge.destroy
    render nothing: true
  end

  private

  def serialized_level
    ExistingLevelSerializer.new(@level.includes(:levels)).to_json
  end

  def find_level_badge
    @level_badge = LevelBadge.find params[:id]
  end
end
