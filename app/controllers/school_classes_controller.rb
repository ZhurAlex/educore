# frozen_string_literal: true

class SchoolClassesController < ApplicationController
  before_action :set_school_class, only: %i[show edit update destroy]

  def index
    authorize SchoolClass
    @school_classes = policy_scope(SchoolClass).order(:name)
  end

  def show
    authorize @school_class
    @students = @school_class.students.order(:last_name, :first_name)
  end

  def new
    authorize SchoolClass
    @school_class = SchoolClass.new
  end

  def edit
    authorize @school_class
  end

  def create
    authorize SchoolClass
    @school_class = SchoolClass.new(school_class_params)

    if @school_class.save
      redirect_to @school_class, notice: t('.success')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    authorize @school_class

    if @school_class.update(school_class_params)
      redirect_to @school_class, notice: t('.success')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize @school_class
    @school_class.destroy
    redirect_to school_classes_path, notice: t('.success')
  end

  private

  def set_school_class
    @school_class = SchoolClass.find(params[:id])
  end

  def school_class_params
    params.require(:school_class).permit(:name)
  end
end
