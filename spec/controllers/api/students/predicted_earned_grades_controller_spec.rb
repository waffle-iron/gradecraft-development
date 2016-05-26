require "rails_spec_helper"

describe API::Students::PredictedEarnedGradesController  do
  let(:world) { World.create.with(:course, :student, :assignment) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      it "assigns the assignments with no call to update" do
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:assignments).current_user).to eq(professor)
        expect(assigns(:assignments).student).to eq(world.student)
        predictor_assignment_attributes.each do |attr|
          expect(assigns(:assignments).assignments[0][attr]).to \
            eq(world.assignment[attr])
        end
        expect(assigns(:assignments).permission_to_update?).to be_falsey
        expect(response).to render_template("api/predicted_earned_grades/index")
      end

      it "assigns a unreleased grade for the assignment with no score data" do
        grade = create(:unreleased_grade, student: world.student, assignment: world.assignment)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:assignments).current_user).to eq(professor)
        expect(assigns(:assignments).student).to eq(world.student)
        expect(assigns(:assignments)[0].prediction[:predicted_points]).to eq(0)
        assigns(:assignments)[0].grade.attributes.tap do |assigned_grade|
          expect(assigned_grade[:id]).to eq(grade.id)
          expect(assigned_grade[:final_points]).to eq(nil)
          expect(assigned_grade[:score]).to eq(nil)
        end
      end

      it "assigns a released grade for the assignment with no predicted score" do
        grade = create(:released_grade, student: world.student, assignment: world.assignment)
        predicted_earned_grade = create(:predicted_earned_grade, assignment: world.assignment, student: world.student)
        get :index, format: :json, student_id: world.student.id
        expect(assigns(:assignments).current_user).to eq(professor)
        expect(assigns(:assignments).student).to eq(world.student)
        expect(assigns(:assignments)[0].prediction[:predicted_points]).to eq(0)
        assigns(:assignments)[0].grade.attributes.tap do |assigned_grade|
          expect(assigned_grade[:id]).to eq(grade.id)
          expect(assigned_grade[:final_points]).to eq(grade.raw_score)
          expect(assigned_grade[:score]).to eq(grade.score)
        end
      end
    end
  end

  # helper methods:
  def predictor_challenge_attributes
    [
      :id,
      :name,
      :description,
      :point_total,
      :visible
    ]
  end
end
