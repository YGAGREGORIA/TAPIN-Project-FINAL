Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  scope "/s/:studio_slug" do
    # NFC/QR landing page — Rajesh
    get "/", to: "studios#show", as: :studio_landing

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

    # Referral system — Rajesh
    resources :referrals, only: [:create] do
      get :share, on: :member
    end
    get "ref/:code", to: "referrals#landing", as: :referral_landing
  end

  resource :dashboard, only: [:show]

  resources :visits, only: [:create]

  # Push notification subscription — Rajesh
  resources :push_subscriptions, only: [:create]

  get "up" => "rails/health#show", as: :rails_health_check

  # PWA manifest and service worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
