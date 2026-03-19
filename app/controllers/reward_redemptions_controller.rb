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
    @redemption = RewardRedemption.find_by!(code: params[:code])
    ActionCable.server.broadcast("reward_redemption_#{@redemption.code}", { event: "scanned" })
    render inline: <<~HTML, layout: false
      <!DOCTYPE html>
      <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Reward Scanned</title>
        <style>
          body { font-family: 'Inter', system-ui, sans-serif; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; background: #F5F0EB; }
          .card { text-align: center; padding: 3rem 2rem; background: white; border-radius: 1rem; box-shadow: 0 4px 20px rgba(0,0,0,0.08); max-width: 340px; }
          .icon { width: 5rem; height: 5rem; border-radius: 50%; background: #87A878; color: white; display: inline-flex; align-items: center; justify-content: center; font-size: 2.5rem; margin-bottom: 1.5rem; }
          h1 { font-size: 1.5rem; color: #2D3319; margin: 0 0 0.5rem; }
          p { color: #6B7280; margin: 0; }
          .code { font-family: monospace; font-weight: 800; font-size: 1.25rem; color: #E07A5F; margin-top: 1rem; }
        </style>
      </head>
      <body>
        <div class="card">
          <div class="icon">&#10003;</div>
          <h1>Reward Verified!</h1>
          <p><strong>#{@redemption.reward.name}</strong></p>
          <p class="code">#{@redemption.code}</p>
          <p style="margin-top: 1rem; font-size: 0.875rem;">This reward has been confirmed. Please serve the customer.</p>
        </div>
      </body>
      </html>
    HTML
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
