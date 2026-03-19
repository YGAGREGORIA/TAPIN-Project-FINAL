class StampCardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  # POST /s/:studio_slug/rewards/:reward_id/start_card
  def create
    reward = @studio.rewards.active.find(params[:id])

    # Check if user already has an active card for this reward
    existing = current_user.stamp_cards.active.find_by(reward: reward)
    if existing
      redirect_to rewards_path(studio_slug: @studio.slug),
        alert: "You already have an active stamp card for #{reward.name}."
      return
    end

    card = current_user.stamp_cards.create!(
      reward: reward,
      studio: @studio,
      started_at: Time.current
    )

    redirect_to rewards_path(studio_slug: @studio.slug),
      notice: "Started stamp card for #{reward.name}! Check in to earn stamps."
  end

  # POST /s/:studio_slug/stamp_cards/:id/redeem
  def redeem
    card = current_user.stamp_cards.completed.find(params[:id])
    redemption = card.redeem!

    redirect_to reward_redemption_path(studio_slug: @studio.slug, id: redemption.id),
      notice: "Reward redeemed! Show your code to staff."
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
