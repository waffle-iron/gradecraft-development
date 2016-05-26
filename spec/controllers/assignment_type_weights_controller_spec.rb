require "rails_spec_helper"

describe AssignmentTypeWeightsController do
  before(:all) do
    @course = create :course,
                   total_assignment_weight: 6,
                   assignment_weight_close_at: Time.now,
                   max_assignment_weight: 2,
                   max_assignment_types_weighted: 4,
                   default_assignment_weight: 1
    @student = create(:user)
    @student.courses << @course
    @assignment_type_weightable = create :assignment_type, course: @course,
      student_weightable: true
  end

  before(:each) do
    session[:course_id] = @course.id
    allow(Resque).to receive(:enqueue).and_return(true)
  end

  context "as professor" do
    before(:all) do
      @professor = create(:user)
      CourseMembership.create user: @professor, course: @course, role: "professor"
    end
    before(:each) { login_user(@professor) }

    describe "GET mass_edit" do
      it "assigns params" do
        get :mass_edit, student_id: @student.id
        expect(assigns(:title)).to eq("Editing #{@student.name}'s multiplier Choices")
        expect(response).to render_template(:mass_edit)
      end
    end

    describe "POST mass_update" do

      before do
        @assignment_type_weightable_2 = create :assignment_type, course: @course,
          student_weightable: true
        @assignment_type_weightable_3 = create :assignment_type, course: @course,
          student_weightable: true
        create :assignment, assignment_type: @assignment_type_weightable,
          course: @course
        create :assignment, assignment_type: @assignment_type_weightable_2,
          course: @course
        create :assignment, assignment_type: @assignment_type_weightable_3,
          course: @course
      end

      it "updates assignment weights" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "2"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "2"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(@student.weight_spent?(@course)).to eq(true)
      end

      it "updates points for corresponding grades" do
        grade = create :released_grade, assignment: @assignment_type_weightable.assignments.first, student: @student, course: @course, raw_score: 1000
        grade_2 = create :released_grade, assignment: @assignment_type_weightable_2.assignments.first, student: @student, course: @course, raw_score: 1000
        grade_3 = create :released_grade, assignment: @assignment_type_weightable_3.assignments.first, student: @student, course: @course, raw_score: 1000
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "2"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "2"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(@assignment_type_weightable.visible_score_for_student(@student)).to eq(2000)
        expect(@assignment_type_weightable_2.visible_score_for_student(@student)).to eq(2000)
        expect(@assignment_type_weightable_3.visible_score_for_student(@student)).to eq(2000)
      end

      it "returns an error message if the student has assigned more weight to an assignment type than is allowed" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "3"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "1"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has not assigned all of their weights" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "1"}} }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has assigned more total weights than allowed" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "3"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "4"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has weighted more assignment types than allowed" do
        @assignment_type_weightable_4 = create :assignment_type, course: @course,
          student_weightable: true
        @assignment_type_weightable_5 = create :assignment_type, course: @course,
          student_weightable: true

        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "1"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "1"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "1" },
        "3" => { "assignment_type_id" => @assignment_type_weightable_4.id, "weight" => "1" },
        "4" => { "assignment_type_id" => @assignment_type_weightable_5.id, "weight" => "2" }} }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end
    end
  end

  context "as student" do
    before(:all) do
      @assignment_type_not_weightable = create(:assignment_type, course: @course, student_weightable: false)
    end
    before(:each) do
      login_user(@student)
      allow(controller).to receive(:current_student).and_return(@student)
    end

    describe "GET mass_edit" do
      it "assigns params" do
        get :mass_edit, student_id: @student.id
        expect(assigns(:title)).to eq("Editing My multiplier Choices")
        expect(response).to render_template(:mass_edit)
      end
    end

    describe "POST mass_update" do

      before do
        @assignment_type_weightable_2 = create :assignment_type, course: @course,
          student_weightable: true
        @assignment_type_weightable_3 = create :assignment_type, course: @course,
          student_weightable: true
        create :assignment, assignment_type: @assignment_type_weightable,
          course: @course
        create :assignment, assignment_type: @assignment_type_weightable_2,
          course: @course
        create :assignment, assignment_type: @assignment_type_weightable_3,
          course: @course
      end

      it "updates assignment weights" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "2"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "2"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(@student.weight_spent?(@course)).to eq(true)
      end

      it "updates points for corresponding grades" do
        grade = create :released_grade, assignment: @assignment_type_weightable.assignments.first, student: @student, course: @course, raw_score: 1000
        grade_2 = create :released_grade, assignment: @assignment_type_weightable_2.assignments.first, student: @student, course: @course, raw_score: 1000
        grade_3 = create :released_grade, assignment: @assignment_type_weightable_3.assignments.first, student: @student, course: @course, raw_score: 1000
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "2"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "2"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(@assignment_type_weightable.visible_score_for_student(@student)).to eq(2000)
        expect(@assignment_type_weightable_2.visible_score_for_student(@student)).to eq(2000)
        expect(@assignment_type_weightable_3.visible_score_for_student(@student)).to eq(2000)
      end

      it "returns an error message if the student has assigned more weight to an assignment type than is allowed" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "3"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "1"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has not assigned all of their weights" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "1"}} }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has assigned more total weights than allowed" do
        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "3"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "4"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "2" } } }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end

      it "returns an error if the student has weighted more assignment types than allowed" do
        @assignment_type_weightable_4 = create :assignment_type, course: @course,
          student_weightable: true
        @assignment_type_weightable_5 = create :assignment_type, course: @course,
          student_weightable: true

        params = { "student" => { "assignment_type_weights_attributes" => { "0" => { "assignment_type_id" => @assignment_type_weightable.id, "weight" => "1"},
        "1" => { "assignment_type_id" => @assignment_type_weightable_2.id, "weight" => "1"},
        "2" => { "assignment_type_id" => @assignment_type_weightable_3.id, "weight" => "1" },
        "3" => { "assignment_type_id" => @assignment_type_weightable_4.id, "weight" => "1" },
        "4" => { "assignment_type_id" => @assignment_type_weightable_5.id, "weight" => "2" }} }, student_id: @student.id }
        post :mass_update, params
        expect(response).to render_template(:mass_edit)
      end
    end

    describe "POST update" do
      before do
        # Won't work unless there is at least one assignment!
        # TODO: refactor weights on assignment type not assignments
        create :assignment, assignment_type: @assignment_type_weightable,
          course: @course
        create :assignment, assignment_type: @assignment_type_not_weightable,
          course: @course
      end

      it "updates assignment weights" do
        post :update, id: @assignment_type_weightable.id, weight: 2, format: :json
        expect(@student.weight_for_assignment_type(@assignment_type_weightable)).to eq(2)
        expect(JSON.parse(response.body)).to eq({ "assignment_type" => @assignment_type_weightable.id, "weight" => 2 })
      end

      it "returns error message when assignment type is not weightable" do
        post :update, id: @assignment_type_not_weightable.id, weight: 2, format: :json
        expect(@student.weight_for_assignment_type(@assignment_type_not_weightable)).to eq(0)
        expect(JSON.parse(response.body)).to eq({"errors"=>"Unable to update assignment type weight"})
      end

      it "updates points for corresponding grades" do
        grade = create :released_grade, assignment: @assignment_type_weightable.assignments.first, student: @student, course: @course, raw_score: 1000
        post :update, id: @assignment_type_weightable.id, weight: 2, format: :json
        expect(@assignment_type_weightable.visible_score_for_student(@student)).to eq(2000)
      end
    end
  end
end
