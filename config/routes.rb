Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
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

  namespace :admin do
    namespace :loyalty do
      patch "deals/referral", to: "deals#update_referral", as: :deals_referral
      resources :deals, only: [:index, :create, :update, :destroy]

      resources :rewards, only: [:index, :create, :update] do
        patch :toggle, on: :member
      end
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
