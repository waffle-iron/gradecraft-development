class StudentAcademicHistoriesController < ApplicationController

  before_filter :ensure_staff?

  before_action :find_student,
    only: [:show, :new, :create, :edit, :update, :destroy]

  def show
    @academic_history =
      @student.student_academic_histories.where(course_id: current_course).first
  end

  def new
    @academic_history = @student.student_academic_histories.new
  end

  def create
    @academic_history =
      @student.student_academic_histories.new(params[:student_academic_history])
    if @academic_history.save
      flash[:notice] =  "#{@student.name}'s Academic History profile was successfully created"
      redirect_to student_path(@student)
    else
      render :new
    end
  end

  def edit
    @academic_history = @student.student_academic_histories.where(course_id: current_course).first
  end

  def update
    @academic_history = @student.student_academic_histories.where(course_id: current_course).first
    @academic_history.update_attributes(params[:student_academic_history])

    if @academic_history.save
      flash[:notice] =  "#{@student.name}'s Academic History profile was successfully updated"
      redirect_to student_path(@student)
    else
      render :edit
    end
  end

  def destroy
    @academic_history = @student.student_academic_histories.where(course_id: current_course).first
    @academic_history.destroy

    respond_to do |format|
      format.html { redirect_to student_path(@student),
          notice: "#{@student.name}'s Academic History Profile was successfully deleted"
        }
    end
  end

  private

  def find_student
    @student = current_course.students.find(params[:student_id])
  end

end
