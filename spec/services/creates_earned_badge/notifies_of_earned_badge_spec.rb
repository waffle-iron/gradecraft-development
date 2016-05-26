require "action_mailer"
require "light-service"
require "active_record_spec_helper"
require "./app/services/creates_earned_badge/notifies_of_earned_badge"
require "./app/mailers/application_mailer"
require "./app/mailers/notification_mailer"

describe Services::Actions::NotifiesOfEarnedBadge do
  let(:delivery) { double(:email) }
  let(:earned_badge) { create :earned_badge }

  it "expects an earned badge to send the notification about" do
    expect { described_class.execute }.to \
      raise_error LightService::ExpectedKeysNotInContextError
  end

  it "sends a notification to the student of the newly awarded badge if the badge is student visible" do
    earned_badge.update_attributes(student_visible: true)
    expect(delivery).to receive(:deliver_now)
    expect(NotificationMailer).to receive(:earned_badge_awarded).with(earned_badge.id).and_return delivery
    described_class.execute earned_badge: earned_badge
  end

  it "does not send the notification if the badge is not student visible" do
    expect(NotificationMailer).to_not receive(:earned_badge_awarded)
    described_class.execute earned_badge: earned_badge
  end
end
