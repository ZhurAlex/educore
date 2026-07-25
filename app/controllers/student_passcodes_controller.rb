class StudentPasscodesController < ApplicationController
  # Public — see docs/SPEC.md "Birth-Date Passcode". Not real authentication,
  # just light protection against a classmate finishing the test as a prank.
  skip_before_action :authenticate_teacher!
  skip_around_action :switch_locale
  around_action :switch_locale_to_test

  before_action :set_test_assignment
  before_action :set_student

  def new
  end

  def create
    if @student.passcode_matches?(params[:passcode])
      # Decision #2 (docs/SPEC.md): one attempt per (student, test), ever,
      # in MVP — reuses an existing attempt (in_progress or completed)
      # rather than creating a second one.
      test_attempt = @student.test_attempts.find_or_create_by!(test: @test_assignment.test) do |attempt|
        attempt.started_at = Time.current
      end

      session[:student_id] = @student.id
      redirect_to test_attempt_path(test_attempt)
    else
      flash.now[:alert] = t(".invalid_passcode")
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_test_assignment
    @test_assignment = TestAssignment.find(params[:test_assignment_id])
  end

  def set_student
    @student = @test_assignment.school_class.students.find(params[:student_id])
  end

  def switch_locale_to_test(&action)
    I18n.with_locale(TestAssignment.find(params[:test_assignment_id]).test.locale, &action)
  end
end
