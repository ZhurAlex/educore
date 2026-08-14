# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    @school_classes = SchoolClass.order(:name)
    @tests = current_teacher.tests.order(:title)
  end
end
