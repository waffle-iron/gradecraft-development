GradeCraft::Application.routes.draw do

  mount RailsEmailPreview::Engine, at: "emails" if Rails.env.development?

  require "admin_constraint"

  #1. Analytics & Charts
  #2. Announcements
  #3. Assignments, Submissions, Tasks, Grades
  #4. Assignment Types
  #5. Assignment Type Weights
  #6. Badges
  #7. Challenges
  #8. Courses
  #9. Groups
  #10. Informational Pages
  #11. Rubrics & Grade Schemes
  #12. Teams
  #13. Users
  #14. User Auth
  #15. Uploads
  #16. Events
  #17. Predictor
  #18. Exports

  #1. Analytics & Charts
  namespace :analytics do
    root action: :index
    get :staff
    get :students
    get :all_events
    get :role_events
    get :assignment_events
    get :login_frequencies
    get :role_login_frequencies
    get :login_events
    get :login_role_events
    get :all_pageview_events
    get :all_role_pageview_events
    get :all_user_pageview_events
    get :pageview_events
    get :role_pageview_events
    get :user_pageview_events
    get :prediction_averages
    get :assignment_prediction_averages
    get :export
  end

  post "analytics_events/predictor_event"
  post "analytics_events/tab_select_event"

  #2. Announcements
  resources :announcements, except: [:destroy, :edit, :update]

  #3. Assignments, Submissions, Tasks, Grades
  resources :assignments do
    collection do
      post :sort
      get :feed
      get :settings
      post "copy" => "assignments#copy"
      get "export_structure"
      get "weights" => "assignment_weights#mass_edit", as: :mass_edit_weights
    end

    # routes for all grades that are associated with an assignment
    # single resources should go directly on the grades controller
    resources :grades, only: [:index], module: :assignments do
      collection do
        get :download
        get :export
        get :export_earned_levels
        get :import
        post :upload
        get :mass_edit
        put :mass_update
        get :edit_status
        put :update_status
        post :self_log
      end
    end

    resources :groups, only: [], module: :assignments do
      get :grade, on: :member
      put :graded, on: :member
    end

    resources :submissions, except: :index

    # TODO: Use plural resource and move to assignments/grades where appropriate
    resource :grade, only: [:edit, :update] do
      resources :earned_badges
    end

    resource :rubric do
      get :existing_criteria
      resources :criteria
      get :design, on: :collection
      get :export
    end
  end

  resources :grades, only: [:show, :destroy] do
    member do
      post :exclude
      post :feedback_read
      post :include
      post :remove
    end
  end

  resources :unlock_states do
    member do
      post :manually_unlock
    end
  end
  resources :unlock_conditions

  # earned badges grade routes
  post "grade/:grade_id/earn_student_badges", to: "grades#earn_student_badges"
  delete "grade/:grade_id/student/:student_id/badge/:badge_id/earned_badge/:id", to: "grades#delete_earned_badge"
  delete "grade/:grade_id/earned_badges", to: "grades#delete_all_earned_badges"

  resources :criteria do
    put :update_order, on: :collection
  end

  resources :levels
  resources :graded_criteria

  resources :level_badges

  #4. Assignment Types
  resources :assignment_types do
    member do
      get "all_grades"
      get "export_scores"
    end
    collection do
      post :sort
      get "export_all_scores"
    end
  end

  #5. Assignment Type Weights
  get "assignment_type_weights" => "assignment_type_weights#mass_edit", as: :assignment_type_weights
  put "assignment_type_weights" => "assignment_type_weights#mass_update"
  post "assignment_type_weight" => "assignment_type_weights#update"

  resources :assignment_weights

  #6. Badges
  resources :badges do

    resources :tasks
    resources :earned_badges
    member do
      get "mass_award" => "earned_badges#mass_edit", as: :mass_award
      post "mass_earn" => "earned_badges#mass_earn"
    end
    collection do
      post :sort
    end
  end

  #7. Challenges
  resources :challenges do
    resources :challenge_grades do
      collection do
        post :edit_status
        put :update_status
        get :mass_edit
      end
    end
    member do
      get "mass_edit" => "challenge_grades#mass_edit", as: :mass_edit
      put "mass_edit" => "challenge_grades#mass_update"
    end
    resources :challenge_files do
      get :remove
    end
  end

  #8. Courses
  resources :courses do
    collection do
      post "copy" => "courses#copy"
    end
    member do
      get "timeline_settings" => "courses#timeline_settings"
      put "timeline_settings" => "courses#timeline_settings_update"
      get "predictor_settings" => "courses#predictor_settings", as: :predictor_settings
      put "predictor_settings" => "courses#predictor_settings_update"
    end
  end
  resources :course_memberships

  get "/current_course/change" => "current_courses#change", as: :change_current_course
  get "current_course" => "current_courses#show"

  get "leaderboard" => "students#leaderboard"
  get "multiplier_choices" => "info#choices"
  get "earned_badges" => "info#awarded_badges"
  get "grading_status" => "info#grading_status"
  get "resubmissions" => "info#resubmissions"
  get "ungraded_submissions" => "info#ungraded_submissions"
  get "top_10" => "info#top_10"
  get "per_assign" => "info#per_assign"
  get "gradebook" => "info#gradebook"
  get "multiplied_gradebook" => "info#multiplied_gradebook"
  get "final_grades" => "info#final_grades"
  get "research_gradebook" => "info#research_gradebook"
  get "export_earned_badges" => "courses#export_earned_badges"

  #9. Groups
  resources :groups do
    resources :proposals
  end
  resources :group_memberships

  #10. Informational Pages
  namespace :info do
    get :choices
    get :awarded_badges
    get :dashboard
    get :grading_status
    get :timeline_events
    get :resubmissions
    get :top_10
    get :per_assign
  end

  resources :home

  get "um_pilot" => "pages#um_pilot"
  get "features" => "pages#features"
  get "press" => "pages#press"
  get "research" => "pages#research"
  get "our_team" => "pages#team"

  #11. Rubrics & Grade Schemes
  resources :rubrics

  #11. Rubrics & Grade Schemes
  resources :grade_scheme_elements do
    collection do
      post :destroy_multiple
      get "mass_edit" => "grade_scheme_elements#mass_edit", as: :mass_edit
      put "mass_edit" => "grade_scheme_elements#mass_update"
    end
  end

  #12. Teams
  resources :teams do
    collection do
      get :activity
    end
    resources :earned_badges
  end

  get "home" => "pages#home"
  get "dashboard" => "info#dashboard"
  get "brand_and_style" => "pages#brand_and_style_guidelines"
  root to: "pages#home"

  #13. Users
  %w{students gsis professors admins}.each do |role|
    get "users/#{role}/new" => "users#new", as: "new_#{role.singularize}", role: role.singularize
  end

  resources :users do
    get :activate, on: :member
    post :activate, on: :member, action: :activated
    post :flag, on: :member
    collection do
      get :edit_profile
      put :update_profile
      get :import
      post :upload
    end
  end
  resources :students do
    get :grade_index
    get :timeline
    get :syllabus
    get :predictor
    get :course_progress
    get :teams
    get :recalculate
    get "badges", to: "students/badges#index"
    get "badges/:id", to: "students/badges#show", as: :badge_show
    resources :student_academic_histories
    collection do
      get :leaderboard
      get :choices
      get :autocomplete_student_name
      get :scores_for_current_course
      get :scores_by_assignment
      get :scores_by_team
      get :scores_for_single_assignment
      get :final_grades
      get :class_badges
      get :flagged
    end
  end
  resources :staff, only: [:index, :show]
  resources :user_sessions
  resources :passwords, path_names: { new: "reset" }, except: [:destroy, :index]

  get "predictor" => "students#predictor"
  get "timeline" => "students#timeline"
  get "syllabus" => "students#syllabus"
  get "course_progress" => "students#course_progress"
  get "my_team" => "students#teams"

  #14. User Auth
  post "auth/lti/callback", to: "user_sessions#lti_create"
  get "auth/failure" => "pages#auth_failure", as: :auth_failure

  get "login" => "user_sessions#new", as: :login
  get "logout" => "user_sessions#destroy", as: :logout
  get "reset" => "user_sessions#new"

  #SAML
  get "saml/init"
  post "saml/consume"
  get "saml/metadata"
  get "saml/logout"

  get "lti/:provider/launch", to: "lti#launch", as: :launch_lti_provider

  #15. Uploads
  resource :uploads do
    get :remove
    get :stuff
    get :remove_submission_file
  end

  #16. Events
  resources :events


  get "gse_mass_edit" => "grade_scheme_elements#mass_edit", defaults: { format: :json }

  #17. API Calls

  namespace :api, defaults: { format: :json } do

    resources :assignments, only: [] do
      resources :criteria, only: :index
      resources :students, only: [] do
        resources :criterion_grades, only: :index
        get "grade", to: 'grades#show'
        put "criterion_grades", to: "criterion_grades#update"
      end
      resources :groups, only: [] do
        get 'grades', to: 'grades#group_index'
        put "criterion_grades", to: "criterion_grades#group_update"
        get 'criterion_grades', to: 'criterion_grades#group_index'
      end
    end

    resources :assignment_types, only: :index
    resources :badges, only: :index
    resources :earned_badges, only: :create
    resources :grades, only: :update
    resources :grade_scheme_elements, only: :index
    resources :levels, only: :update

    # Student Predictor View, Predictor Preview
    resources :predicted_earned_badges, only: [:index, :update]
    resources :predicted_earned_challenges, only: [:index, :update]
    resources :predicted_earned_grades, only: [:index, :update]

    # Instructor View of Student's Predictor
    resources :students, only: [], module: :students do
      get "assignment_types", to: "assignment_types#index"
      get "predicted_earned_badges", to: "predicted_earned_badges#index"
      get "predicted_earned_challenges", to: "predicted_earned_challenges#index"
      get "predicted_earned_grades", to: "predicted_earned_grades#index"
    end
  end

  #18. Exports
  resources :exports
  get "exports_controller/index"

  #19. SubmissionsExports
  resources :submissions_exports do
    member do
      get :download
      get '/secure_download/:secure_token_uuid/secret_key/:secret_key',
        action: "secure_download", as: "secure_download"
    end
  end
end
