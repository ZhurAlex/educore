# frozen_string_literal: true

require 'sidekiq/web'

Rails.application.routes.draw do
  # Registration is closed — see docs/SPEC.md Decision #11. The Teacher
  # model has no :registerable module, so devise_for already skips those
  # routes; :skip here is just belt-and-braces documentation of intent.
  devise_for :teachers, skip: [:registrations]

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  get 'dashboard', to: 'dashboard#show', as: :dashboard

  # Public student entry point (docs/SPEC.md Decision #14, revised) — browse
  # to your *test history* without needing a saved QR link. Deliberately
  # separate from the QR flow below, which is the only way to start/resume a
  # test: root lists classes, StudentEntryController#show lists that class's
  # students (name + initial only — see Decision #14 discussion), then
  # StudentHistoryController re-checks the DDMM passcode (a fresh login, not
  # the same session as an in-progress QR attempt) before listing that
  # student's own attempts across every test.
  root to: 'student_entry#index'
  get 'start/:school_class_id', to: 'student_entry#show', as: :student_entry
  get 'start/:school_class_id/students/:student_id/login',
      to: 'student_history#new', as: :student_history_login
  post 'start/:school_class_id/students/:student_id/login',
       to: 'student_history#create'
  get 'start/:school_class_id/students/:student_id/history',
      to: 'student_history#index', as: :student_history

  # Teacher-side locale switcher — session-based, since the teacher has a
  # persistent Devise session (see docs/SPEC.md I18n section / Decision #8).
  patch 'locale', to: 'locales#update', as: :locale

  resources :school_classes do
    resources :students, except: %i[index show], shallow: true
  end

  resources :tests do
    resources :questions, except: %i[index show], shallow: true
    # :show is the QR code target — public, no teacher auth (see
    # docs/SPEC.md I18n section: "QR code links straight to
    # /test_assignments/:id"). It's also where the student flow (build
    # order step 6) will land.
    resources :test_assignments, only: %i[new create show destroy], shallow: true
    # Teacher-facing results (build order step 8) — distinct from the public
    # `test_attempts` resource below (student-facing, no teacher auth).
    resources :attempts, only: %i[index show], shallow: true
  end

  resources :responses, only: [:update]

  # Student flow (build order step 6) — all public, no teacher auth. See
  # docs/SPEC.md User Flow steps 3-6 and "Birth-Date Passcode".
  get 'test_assignments/:test_assignment_id/students/:student_id/passcode',
      to: 'student_passcodes#new', as: :student_passcode
  post 'test_assignments/:test_assignment_id/students/:student_id/passcode',
       to: 'student_passcodes#create'

  resources :test_attempts, only: %i[show update]

  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  authenticate :teacher do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :api do
    resources :test_attempts, only: [:index]
  end
end
