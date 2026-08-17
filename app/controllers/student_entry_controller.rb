# frozen_string_literal: true

class StudentEntryController < ApplicationController
  # Public — the entry point for students browsing to their test history
  # without a saved link (docs/SPEC.md Decision #14, revised). No teacher
  # auth; only names (with initials, not full) and class names are shown
  # here — actual results still require a DDMM login (StudentHistoryController).
  skip_before_action :authenticate_teacher!

  before_action :set_school_class, only: :show

  def index
    @school_classes = SchoolClass.order(:name)
  end

  def show
    @students = @school_class.students.order(:last_name, :first_name)
  end

  private

  def set_school_class
    @school_class = SchoolClass.find(params[:school_class_id])
  end
end
