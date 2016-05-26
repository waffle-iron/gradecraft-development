class TeamLeadership < ActiveRecord::Base
  attr_accessible :team, :team_id, :leader, :leader_id

  belongs_to :team
  belongs_to :leader, class_name: "User"

  validates_presence_of :team, :leader
end
