# frozen_string_literal: true

module Api
  class ApplicationController < ActionController::Base
    before_action :authenticate_api_token!

    def authenticate_api_token!
      token = request.headers['Authorization']&.remove('Bearer ')
      head :unauthorized unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, ENV.fetch('ANALYTICS_API_KEY'))
    end
  end
end
