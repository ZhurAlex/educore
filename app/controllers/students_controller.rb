class StudentsController < ApplicationController
  before_action :set_school_class, only: [ :new, :create ]
  before_action :set_student, only: [ :edit, :update, :destroy ]

  def new
    authorize Student
    @student = @school_class.students.new
  end

  def create
    authorize Student
    @student = @school_class.students.new(student_params)

    if @student.save
      redirect_to @school_class, notice: t(".success")
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    authorize @student
  end

  def update
    authorize @student

    if @student.update(student_params)
      redirect_to @student.school_class, notice: t(".success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @student
    school_class = @student.school_class
    @student.destroy
    redirect_to school_class, notice: t(".success")
  end

  private

  def set_school_class
    @school_class = SchoolClass.find(params[:school_class_id])
  end

  def set_student
    @student = Student.find(params[:id])
  end

  def student_params
    params.require(:student).permit(:first_name, :last_name, :birth_date)
  end
end
