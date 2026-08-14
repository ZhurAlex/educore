# frozen_string_literal: true

class LocalesController < ApplicationController
  def update
    session[:locale] = params[:locale] if I18n.available_locales.map(&:to_s).include?(params[:locale])

    redirect_back_or_to(root_path)
  end
end
