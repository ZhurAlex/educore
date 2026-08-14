# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Teacher-side locale switching (session-based) — see docs/SPEC.md I18n
  # section. Student-facing controllers (build order step 6) will instead
  # read locale off the assigned Test, not the session.
  around_action :switch_locale

  # Every controller so far is teacher-admin-only. Student-facing controllers
  # (build order step 6) will need `skip_before_action :authenticate_teacher!`.
  before_action :authenticate_teacher!

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def switch_locale(&)
    I18n.with_locale(session[:locale] || I18n.default_locale, &)
  end

  # Devise scope is :teacher (not the default :user), so Pundit needs to be
  # told explicitly which current_* method to authorize against.
  def pundit_user
    current_teacher
  end

  def user_not_authorized
    flash[:alert] = t('pundit.not_authorized')
    redirect_back_or_to(root_path)
  end
end
