Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  scope "/s/:studio_slug" do
    resources :rewards, only: [ :index ] do
      post :redeem, to: "reward_redemptions#create", on: :member
    end

    resources :reward_redemptions, only: [ :index, :show ]

    resources :deals, only: [ :index ] do
      post :claim, to: "deal_claims#create", on: :member
    end

    resources :deal_claims, only: [ :show ]

    resources :classes, only: [ :index, :show ] do
      post :book, to: "bookings#create", on: :member
    end

    resources :bookings, only: [ :index, :show, :destroy ]

    resources :mindbody_links, only: [ :new ]
  end

  resource :dashboard, only: [:show]

  resources :visits, only: [:create]

  # === Admin namespace ===
  namespace :admin do
    # Navid's areas
    resource :dashboard, only: [:show]
    resources :rewards
    resources :class_configs, only: [:index, :update]
    resources :deals do
      patch :update_referral, on: :collection
    end
    resources :members, only: [:index, :show, :export] do
      post :points, to: "member_points#create", on: :member
      post :rewards, to: "member_rewards#create", on: :member
      get :export, on: :collection
    end

    # Raj's areas
    resource :checkin_settings, only: [:show, :update] do
      get :nfc_guide
      post :test
    end
    resources :mindbody_matches, only: [:index] do
      member do
        post :confirm
        post :reject
      end
    end
    resources :mindbody_conflicts, only: [:show]
    resources :notification_templates, only: [:index, :update]
    resources :broadcasts, only: [:index, :create]
    resource :assistant, only: [:show], controller: "assistant" do
      post :respond
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
