class PushSubscriptionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    sub = current_user.push_subscriptions.find_or_initialize_by(
      endpoint: params.dig(:push_subscription, :endpoint)
    )
    sub.p256dh_key = params.dig(:push_subscription, :p256dh_key)
    sub.auth_key = params.dig(:push_subscription, :auth_key)

    if sub.save
      head :ok
    else
      head :unprocessable_entity
    end
  end
end
