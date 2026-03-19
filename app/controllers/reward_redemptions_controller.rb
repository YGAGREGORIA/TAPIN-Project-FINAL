class RewardRedemptionsController < ApplicationController
  before_action :authenticate_user!, except: [:scan]
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
    scan_url = scan_reward_redemptions_url(studio_slug: @studio.slug, code: @reward_redemption.code)
    qr = RQRCode::QRCode.new(scan_url)
    @qr_svg = qr.as_svg(
      color: "000",
      shape_rendering: "crispEdges",
      module_size: 4,
      standalone: true,
      use_path: true
    )
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

  def scan
    redemption = RewardRedemption.find_by!(code: params[:code])
    ActionCable.server.broadcast("reward_redemption_#{redemption.code}", { event: "scanned" })
    head :ok
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
