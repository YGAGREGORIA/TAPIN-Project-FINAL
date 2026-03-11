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
  end

  resource :dashboard, only: [:show]

  resources :visits, only: [:create]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
