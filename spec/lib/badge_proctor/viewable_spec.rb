require "./lib/badge_proctor"

describe BadgeProctor::Viewable do
  let(:course) { double(:course, id: 456) }
  let(:badge) { double(:badge, id: 789, course_id: course.id, visible?: false) }
  let(:user) { double(:user, id: 123, is_staff?: false) }

  describe "#viewable?" do
    subject { BadgeProctor.new(badge) }

    it "cannot be viewable if the badge is nil" do
      subject = BadgeProctor.new(nil)
      expect(subject).to_not be_viewable user, course: course
    end

    context "as a student" do
      it "cannot view the badge if it's not visible" do
        expect(subject).to_not be_viewable user, course: course
      end

      it "cannot view the badge if it's not part of the course" do
        allow(badge).to receive(:course_id).and_return 789
        expect(subject).to_not be_viewable user, course: course
      end

      it "can view the badge if it's visible" do
        allow(badge).to receive(:visible?).and_return true
        expect(subject).to be_viewable user, course: course
      end

      it "can view the badge if earned and the EarnedBadge is visible" do
        world = World.create.create_badge
        eb = create(:earned_badge,
          course: world.course,
          badge: world.badge,
          student_visible: true)
        subject = BadgeProctor.new(world.badge)
        expect(subject).to be_viewable eb.student, course: eb.course
      end

      it "cannnot view the badge if earned but the EarnedBadge is invisible" do
        world = World.create.create_badge(visible: false)
        eb = create(:earned_badge,
          course: world.course,
          badge: world.badge,
          student_visible: false)
        subject = BadgeProctor.new(world.badge)
        expect(subject).to_not be_viewable eb.student, course: eb.course
      end

      context "with level in options" do
        it "is visible if the badge is earned for that level" do
          world = World.create.create_badge(visible: false)
          level = create(:level)
          eb = create(:earned_badge,
            course: world.course,
            badge: world.badge,
            level_id: level.id,
            student_visible: true)
          subject = BadgeProctor.new(world.badge)
          expect(subject).to be_viewable eb.student,
            level: level, course: eb.course
        end

        it "is not visible if the badge is earned but not for that level" do
          world = World.create.create_badge(visible: false)
          level = create(:level)
          eb = create(:earned_badge,
            course: world.course,
            badge: world.badge,
            student_visible: true)
          subject = BadgeProctor.new(world.badge)
          expect(subject).to_not be_viewable eb.student,
            level: level, course: eb.course
        end
      end
    end

    context "as staff" do
      let(:staff) { double(:user, id: 456, is_staff?: true) }

      it "can view the badge if they're an instructor for the course" do
        expect(subject).to be_viewable staff, course: course
      end

      it "cannot view the badge if they're not an instructor for the course" do
        allow(staff).to receive(:is_staff?).with(course).and_return false
        expect(subject).to_not be_viewable staff, course: course
      end
    end
  end
end
