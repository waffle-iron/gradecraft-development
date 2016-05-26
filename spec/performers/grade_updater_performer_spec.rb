require "rails_spec_helper"

RSpec.describe GradeUpdatePerformer, type: :background_job do
  let(:assignment) { create(:assignment) }
  let(:grade) { create(:grade, assignment_id: assignment.id) }
  let(:attrs) {{ grade_id: grade[:id] }}
  let(:performer) { GradeUpdatePerformer.new(attrs) }
  subject { performer }

  describe "public methods" do
    describe "setup" do
      it "should fetch the user and set it to user" do
        expect(subject).to receive(:fetch_grade_with_assignment).and_return grade
        subject.setup
        expect(subject.instance_variable_get(:@grade)).to eq(grade)
      end
    end

    describe "do_the_work" do
      subject { performer.do_the_work }
      after(:each) { subject }

      it "should require that the saved scores method succeeds" do
        expect(performer).to receive(:require_save_scores_success)
      end

      it "should require that the notify released method succeeds" do
        expect(performer).to receive(:require_notify_released_success)
      end
    end

    describe "require_saved_scores_success" do
      let(:save_scores_messages) { double(:save_scores_messages) }
      let(:performer_grade) { performer.instance_variable_get(:@grade) }
      subject { performer.instance_eval { require_save_scores_success }}

      it "should require success with notify released messages" do
        allow(performer).to receive(:save_scores_messages) { save_scores_messages }
        expect(performer).to receive(:require_success).with(save_scores_messages)
        subject
      end

      context "@grade.cache_student_and_team_scores succeeds" do
        before(:each) do
          allow(performer_grade).to receive_messages(cache_student_and_team_scores: true)
        end

        it "should return the successful value" do
          expect(performer).to receive(:require_success) { true }
          subject
        end

        it "should change the number of outcomes" do
          expect{ subject }.to change{ performer.outcomes.size }.by(1)
        end

        it "should create a successful outcome" do
          subject
          expect(performer.outcomes.first.success?).to be_truthy
        end

        it "should use the proper message in the outcome" do
          subject
          expect(performer.outcome_messages.first).to match(/saved successfully for grade/)
        end
      end

      context "@grade.cache_student_and_team_scores fails" do
        before(:each) do
          allow(performer_grade).to receive_messages(cache_student_and_team_scores: nil)
        end

        it "should return the successful value" do
          expect(performer).to receive(:require_success) { nil }
          subject
        end

        it "should change the number of outcomes" do
          expect{ subject }.to change{ performer.outcomes.size }.by(1)
        end

        it "should create a failed outcome" do
          subject
          expect(performer.outcomes.first.failure?).to be_truthy
        end

        it "should use the correct message in the outcome" do
          subject
          expect(performer.outcome_messages.first).to match(/scores failed to save/)
        end
      end
    end

    describe "require_notify_released_success" do
      subject { performer.instance_eval { require_notify_released_success } }
      let(:notify_released_messages) { double(:notify_released_messages) }
      let(:notify_grade_released) { double(:notify_grade_released) }
      let(:notify_released_result) { double(:notify_released_result) }
      let(:performer_grade) { performer.instance_variable_get(:@grade) }
      let(:cache_performer) { performer; performer_grade; }

      context "@grade is student visible and grade assignment is set to notify on release" do
        before(:each) do
          allow_any_instance_of(GradeProctor).to receive(:viewable?) { true }
          allow(performer_grade).to receive_message_chain(:assignment, :notify_released?) { true }
        end

        it "should require success with notify released messages" do
          allow(performer).to receive_messages(notify_released_messages: notify_released_messages)
          expect(performer).to receive(:require_success).with(notify_released_messages, { max_result_size: 200 })
          subject
        end

        it "should render the value of notify_grade_released" do
          allow(performer).to receive(:notify_grade_released) { true }
          expect(performer).to receive(:require_success) { true }
          subject
        end

        it "should return the result of notify_grade_released" do
          allow(performer).to receive_messages(notify_grade_released: notify_released_result)
          expect(subject.result).to eq(notify_released_result)
        end

        it "should change the number of outcomes" do
          expect{ subject }.to change{ performer.outcomes.size }.by(1)
        end

        it "should create a successful outcome" do
          subject
          expect(performer.outcomes.first.success?).to be_truthy
        end

        it "should use the correct message in the outcome" do
          subject
          expect(performer.outcome_messages.first).to match(/Successfully sent notification/)
        end
      end

      context "@grade assignment is not set to notify on release but grade is student visible" do
        before(:each) do
          allow_any_instance_of(GradeProctor).to receive(:viewable?) { true }
          allow(performer_grade).to receive_message_chain(:assignment, :notify_released?) { false }
        end

        it "should not trigger the require success" do
          expect(performer).not_to receive(:require_success)
          subject
        end

        it "should return nil" do
          expect(subject).to eq(nil)
        end
      end

      context "@grade assignment is set to notify on release but grade is not student visible" do
        before(:each) do
          allow_any_instance_of(GradeProctor).to receive(:viewable?) { false }
          allow(performer_grade).to receive_message_chain(:assignment, :notify_released?) { true }
        end

        it "should not trigger the require success" do
          expect(performer).not_to receive(:require_success)
          subject
        end

        it "should return nil" do
          expect(subject).to eq(nil)
        end
      end

      context "@grade assignment is not set to notify on release and grade is not student visible" do
        before(:each) do
          allow_any_instance_of(GradeProctor).to \
            receive(:viewable?).and_return false
          allow(performer_grade).to receive_message_chain(:assignment, :notify_released?) { false }
        end

        it "should not trigger the require success" do
          expect(performer).not_to receive(:require_success)
          subject
        end

        it "should return nil" do
          expect(subject).to eq(nil)
        end
      end

    end
  end

  describe "fetch_grade_with_assignment" do
    subject { performer.instance_eval{ fetch_grade_with_assignment } }
    let(:include_result) { double(:include_result).as_null_object }
    let(:fetch_grade) { Grade.find grade.id }

    it "should find a grade where the id matches @attrs[:grade_id]" do
      allow(Grade).to receive(:where) { include_result }
      expect(Grade).to receive(:where).with(id: attrs[:grade_id])
      subject
    end

    it "should include the assignment" do
      allow(Grade).to receive(:where) { include_result }
      expect(include_result).to receive(:includes).with(:assignment)
      subject
    end

    it "should load the first one" do
      expect(Grade).to receive_message_chain(:where, :includes, :load, :first)
      performer
    end

    it "should return the actual grade" do
      expect(subject).to eq(fetch_grade)
    end

    it "should have included the assignment" do
      subject
      expect{ grade.assignment }.not_to make_database_queries
    end
  end

  describe "notify_grade_released" do
    subject { performer.instance_eval { notify_grade_released } }
    let(:mailer_double) { double(:mailer).as_null_object }
    before(:each) { allow(NotificationMailer).to receive(:grade_released).and_return(mailer_double) }
    after(:each) { subject }

    it "should create a new grade released notifier with the grade id" do
      expect(NotificationMailer).to receive(:grade_released).with(grade.id)
    end

    it "should deliver the mailer" do
      allow(performer).to receive_messages(grade_released:  mailer_double)
      expect(mailer_double).to receive(:deliver_now)
    end
  end

  describe "save_scores_messages" do
    subject { performer.instance_eval{ save_scores_messages } }
    let(:performer_grade) { performer.instance_variable_get(:@grade) }

    it "should have a success message" do
      expect(subject[:success]).to match("saved successfully")
    end

    it "should have a failure message" do
      expect(subject[:failure]).to match("failed to save")
    end

    it "should include the grade id in the success condition" do
      expect(subject[:success]).to match("for grade ##{performer_grade.id}")
    end

    it "should include the grade id in the failure condition" do
      expect(subject[:failure]).to match("for grade ##{performer_grade.id}")
    end
  end

  describe "notify_released_messages" do
    subject { performer.instance_eval{ notify_released_messages } }

    it "should have a success message" do
      expect(subject[:success]).to include("Successfully sent notification")
    end

    it "should have a failure message" do
      expect(subject[:failure]).to include("Failed to send")
    end
  end
end
