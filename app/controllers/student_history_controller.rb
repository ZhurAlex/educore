# frozen_string_literal: true

class StudentHistoryController < ApplicationController
  # Public — see docs/SPEC.md "Birth-Date Passcode". A separate login from
  # StudentPasscodesController: that one is scoped to a single test
  # assignment (start/resume one attempt), this one is scoped to a student
  # across their whole class (view every attempt they've ever made).
  skip_before_action :authenticate_teacher!

  before_action :set_school_class
  before_action :set_student
  before_action :verify_owner!, only: :index

  def index
    @test_attempts = @student.test_attempts.includes(:test).order(started_at: :desc)
  end

  def new; end

  def create
    if @student.passcode_matches?(params[:passcode])
      session[:student_id] = @student.id
      redirect_to student_history_path(@school_class, @student)
    else
      flash.now[:alert] = t('student_passcodes.create.invalid_passcode')
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_school_class
    @school_class = SchoolClass.find(params[:school_class_id])
  end

  def set_student
    @student = @school_class.students.find(params[:student_id])
  end

  def verify_owner!
    head :forbidden unless session[:student_id] == @student.id
  end
end
