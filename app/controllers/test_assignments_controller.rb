# frozen_string_literal: true

class TestAssignmentsController < ApplicationController
  # :show is the public QR-code target — see routes.rb. Locale there comes
  # from the Test itself (docs/SPEC.md Decision #8), not the teacher's
  # session, so it needs its own locale handling instead of the parent's.
  skip_before_action :authenticate_teacher!, only: [:show]
  skip_around_action :switch_locale, only: [:show]
  around_action :switch_locale_to_test, only: [:show]

  before_action :set_test, only: %i[new create]
  before_action :set_test_assignment, only: %i[show destroy]

  # Public: no authorization check — this is the QR/student entry point,
  # not a teacher-admin action. Renders the class roster; picking a name
  # continues to StudentPasscodesController.
  def show
    @students = @test_assignment.school_class.students.order(:last_name, :first_name)
  end

  def new
    @test_assignment = @test.test_assignments.new
    authorize @test_assignment
    @available_school_classes = SchoolClass.where.not(id: @test.school_classes.select(:id)).order(:name)
  end

  def create
    @test_assignment = @test.test_assignments.new(test_assignment_params)
    authorize @test_assignment

    if @test_assignment.save
      redirect_to @test, notice: t('.success')
    else
      @available_school_classes = SchoolClass.where.not(id: @test.school_classes.select(:id)).order(:name)
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    authorize @test_assignment
    test = @test_assignment.test
    @test_assignment.destroy
    redirect_to test, notice: t('.success')
  end

  private

  def set_test
    @test = Test.find(params[:test_id])
  end

  def set_test_assignment
    @test_assignment = TestAssignment.find(params[:id])
  end

  def test_assignment_params
    params.require(:test_assignment).permit(:school_class_id)
  end

  def switch_locale_to_test(&)
    # Doesn't rely on @test_assignment/set_test_assignment — around_action
    # callbacks run before before_action ones in the declaration order used
    # here, so @test_assignment wouldn't be set yet.
    locale = TestAssignment.find(params[:id]).test.locale
    I18n.with_locale(locale, &)
  end
end
