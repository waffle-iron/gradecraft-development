require "active_record_spec_helper"

describe AssignmentTypeWeight do

  describe "#weight" do 

    it "returns the value of the first assignment weight in the type for the student if present" do 
      course = create(:course)
      assignment_type = create(:assignment_type, course: course)
      student = create(:user)
      assignment_weight = create(:assignment_weight, student: student, assignment_type: assignment_type, course: course, weight: 3)
      subject = AssignmentTypeWeight.new(student, assignment_type)

      expect(subject.weight).to eq(3)
    end 
  end

  describe "#assignment_type_id" do
    it "returns the value of the first assignment weight in the type for the student if present" do 
      course = create(:course)
      assignment_type = create(:assignment_type, course: course)
      student = create(:user)
      assignment_weight = create(:assignment_weight, student: student, assignment_type: assignment_type, course: course, weight: 3)
      subject = AssignmentTypeWeight.new(student, assignment_type)

      expect(subject.assignment_type_id).to eq(assignment_type.id)
    end 
  end

  describe "#save" do
    # if valid?
    #   save_assignment_weights
    #   true
    # else
    #   false
    # end
  end

end
