# frozen_string_literal: true

module Api
  class StudentsController < Api::ApplicationController
    def index
      render json: Student.for_school_class(index_params[:school_class_id])
                          .select(:id, :first_name, :last_name)
                          .map { |s| { id: s.id, name: s.full_name } }
    end

    private

    def index_params
      params.permit(:school_class_id)
    end
  end
end
