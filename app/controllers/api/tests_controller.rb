# frozen_string_literal: true

module Api
  class TestsController < Api::ApplicationController
    def index
      render json: Test.for_school_class(index_params[:school_class_id]).select(:id, :title).as_json
    end

    private

    def index_params
      params.permit(:school_class_id)
    end
  end
end
