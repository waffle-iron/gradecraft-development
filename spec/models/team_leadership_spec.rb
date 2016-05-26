require "active_record_spec_helper"

describe TeamLeadership do 

  subject { build(:team_leadership) }

  context "validations" do
    it "is valid with a team, and a leader" do
      expect(subject).to be_valid
    end
  end

end
