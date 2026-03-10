class RewardRedemptionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def index
    @reward_redemptions = current_user.reward_redemptions
                                      .where(studio: @studio)
                                      .latest_first
  end

  def show
    @reward_redemption = current_user.reward_redemptions
                                     .where(studio: @studio)
                                     .find(params[:id])
  end

  def create
    reward = @studio.rewards.find(params[:id])

    unless reward.redeemable_by?(current_user)
      redirect_to rewards_path(studio_slug: @studio.slug),
                  alert: "This reward is not available yet."
      return
    end

    @reward_redemption = current_user.reward_redemptions.new(
      reward: reward,
      studio: @studio
    )

    if @reward_redemption.save
      redirect_to reward_redemption_path(studio_slug: @studio.slug, id: @reward_redemption.id),
                  notice: "Reward redeemed successfully."
    else
      redirect_to rewards_path(studio_slug: @studio.slug),
                  alert: @reward_redemption.errors.full_messages.to_sentence
    end
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
