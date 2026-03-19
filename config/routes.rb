Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    registrations: "users/registrations"
  }
  root to: "pages#home"

  scope "/s/:studio_slug" do
    get "/", to: "studios#show", as: :studio_landing
    post "checkin", to: "studios#checkin", as: :studio_checkin

    # Phone-based member auth
    get "login", to: "phone_sessions#new", as: :studio_phone_login
    post "login", to: "phone_sessions#create"
    get "verify", to: "phone_sessions#verify", as: :studio_phone_verify
    post "verify", to: "phone_sessions#confirm"
    delete "logout", to: "phone_sessions#destroy", as: :studio_phone_logout

    resources :rewards, only: [ :index ] do
      post :redeem, to: "reward_redemptions#create", on: :member
      post :start_card, to: "stamp_cards#create", on: :member
    end

    resources :stamp_cards, only: [] do
      post :redeem, on: :member
    end

    resources :reward_redemptions, only: [ :index, :show ] do
      collection do
        get "scan/:code", action: :scan, as: :scan
      end
    end

    resources :deals, only: [ :index ] do
      post :claim, to: "deal_claims#create", on: :member
    end

    resources :deal_claims, only: [ :show ]

    resources :classes, only: [ :index, :show ] do
      post :book, to: "bookings#create", on: :member
    end

    resources :bookings, only: [ :index, :show, :destroy ]

    resources :mindbody_links, only: [ :new ]

    # Referral system — Rajesh
    resources :referrals, only: [ :create ] do
      get :share, on: :member
    end
    get "ref/:code", to: "referrals#landing", as: :referral_landing
  end

  resource :dashboard, only: [ :show ]

  resources :visits, only: [ :create ]

  namespace :admin do
    namespace :loyalty do
      patch "deals/referral", to: "deals#update_referral", as: :deals_referral
      resources :deals, only: [ :index, :create, :update, :destroy ]

      resources :rewards, only: [ :index, :create, :update ] do
        patch :toggle, on: :member
      end
    end

    resource :dashboard, only: [ :show ]
    resources :rewards do
      get :confirm_delete, on: :member
    end
    resource :onboarding, only: [ :show ], controller: "onboarding" do
      post :advance
      post :goto
      post :save_branding
      post :apply_branding
      post :regenerate_branding
      # Safety redirects — Turbo Drive can cache POST URLs and hit them with GET
      get :save_branding,       to: redirect("/admin/onboarding")
      get :apply_branding,      to: redirect("/admin/onboarding")
      get :regenerate_branding, to: redirect("/admin/onboarding")
    end
    resources :rewards
    resources :classes, only: [ :index, :show ], controller: "classes"
    resources :class_configs, only: [ :index, :update ]
    resources :deals do
      get :confirm_delete, on: :member
      patch :update_referral, on: :collection
    end
    resources :members, only: [:index, :show] do
      post :points, to: "member_points#create", on: :member
      post :rewards, to: "member_rewards#create", on: :member
      get :export, on: :collection
    end

    # Raj's areas
    resource :checkin_settings, only: [ :show, :update ] do
      get :nfc_guide
      post :test
    end
    resources :mindbody_matches, only: [ :index ] do
      member do
        post :confirm
        post :reject
      end
    end
    resources :mindbody_conflicts, only: [ :show ]
    resources :notification_templates, only: [ :index, :update ]
    resources :broadcasts, only: [ :index, :create ]
    resource :assistant, only: [ :show ], controller: "assistant" do
      post :respond
      get :chats, defaults: { format: :json }
      get :chat_messages, defaults: { format: :json }
    end
    resource :analytics, only: [ :show ], controller: "analytics" do
      get :points
      get :loyalty
    end
  end

  # AI Assistant — Rajesh
  resources :chats, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
  end

  # Push notification subscription — Rajesh
  resources :push_subscriptions, only: [ :create ]
  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
