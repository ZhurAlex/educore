# frozen_string_literal: true

module Api
  class SchoolClassesController < Api::ApplicationController
    def index
      render json: SchoolClass.select(:id, :name).as_json
    end
  end
end
