# frozen_string_literal: true

class StudentEntryController < ApplicationController
  # Public — the entry point for students browsing to their test without a
  # saved QR link (docs/SPEC.md Decision #14, revised). No teacher auth;
  # actual answers still stay behind the DDMM passcode
  # (StudentPasscodesController), this only lists class/test names.
  skip_before_action :authenticate_teacher!

  before_action :set_school_class, only: :show
  before_action :set_test_assignment, only: :results

  def index
    @school_classes = SchoolClass.order(:name)
  end

  def show
    @test_assignments = @school_class.test_assignments.includes(:test).sort_by { |ta| ta.test.title }
  end

  # Only students who've actually completed this test — a fresh/in-progress
  # roster belongs to the QR entry point (TestAssignmentsController#show),
  # not here, since this screen exists purely to find your own results.
  def results
    students = @test_assignment.school_class.students
    @completed_attempts = TestAttempt.completed
                                     .where(test: @test_assignment.test, student: students)
                                     .includes(:student)
                                     .sort_by { |attempt| [attempt.student.last_name, attempt.student.first_name] }
  end

  private

  def set_school_class
    @school_class = SchoolClass.find(params[:school_class_id])
  end

  def set_test_assignment
    @test_assignment = TestAssignment.find(params[:test_assignment_id])
  end
end
