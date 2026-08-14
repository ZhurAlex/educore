# frozen_string_literal: true

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
  # to your *results* without needing a saved QR link: root lists classes,
  # StudentEntryController#show lists that class's tests, #results lists only
  # the students who've already completed the chosen test (unlike the QR
  # roster below, which intentionally lists everyone so they can start).
  root to: 'student_entry#index'
  get 'start/:school_class_id', to: 'student_entry#show', as: :student_entry
  get 'start/:school_class_id/tests/:test_assignment_id', to: 'student_entry#results', as: :student_entry_results

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
end
