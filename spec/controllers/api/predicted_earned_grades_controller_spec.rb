require "rails_spec_helper"

describe API::PredictedEarnedGradesController do
  let(:world) { World.create.with(:course, :student, :assignment) }
  let(:professor) { create(:professor_course_membership, course: world.course).user }

  context "as professor" do
    before(:each) { login_user(professor) }

    describe "GET index" do
      before do
        allow(controller).to receive(:current_course).and_return(world.course)
        allow(controller).to receive(:current_user).and_return(professor)
      end

      context "with no student" do
        it "assigns student as null student and no call to update" do
          get :index, format: :json
          expect(assigns(:assignments).student.class).to eq(NullStudent)
        end
      end
    end
  end

  context "as student" do
    before do
      login_user(world.student)
      allow(controller).to receive(:current_course).and_return(world.course)
    end

    describe "GET index" do
      it "assigns the attributes with call to update" do
        get :index, format: :json, id: world.student.id
        expect(assigns(:assignments).class).to eq(PredictedAssignmentCollectionSerializer)
        expect(response).to render_template(:index)
      end
    end

    describe "PUT update" do
      it "updates the predicted points for a grade" do
        predicted_earned_grade = create(:predicted_earned_grade, assignment: world.assignment, student: world.student)
        predicted_points = (world.assignment.point_total * 0.75).to_i
        put :update, id: predicted_earned_grade.id, predicted_points: predicted_points, format: :json
        expect(PredictedEarnedGrade.where(student: world.student, assignment: world.assignment).first.predicted_points).to eq(predicted_points)
        expect(JSON.parse(response.body)).to eq({"id" => predicted_earned_grade.id, "predicted_points" => predicted_points})
      end

      it "renders a 404 if prediction not found" do
        put :update, id: 0, predicted_points: 0, format: :json
        expect(response.status).to eq(404)
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
