class RewardRedemptionChannel < ApplicationCable::Channel
  def subscribed
    stream_from "reward_redemption_#{params[:code]}"
  end
end
