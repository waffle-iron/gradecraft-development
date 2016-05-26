require "rails_spec_helper"

describe API::EarnedBadgesController do
  let(:world) { World.create.with(:course, :student, :badge) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "POST create" do
      it "creates a new student badge from params" do
          params = { earned_badge:
                     { badge_id: world.badge.id, student_id: world.student.id }}
          expect{post :create, params.merge(format: :json)}.to \
            change {EarnedBadge.count}.by(1)
        end
    end
  end
end
