class Admin::DashboardsController < Admin::BaseController
  def show
    @studio = current_studio

    @total_members      = User.where(admin: false).count
    @total_visits       = @studio ? Visit.where(studio: @studio).count : 0
    @active_deals       = @studio ? Deal.where(studio: @studio, active: true).count : 0
    @active_rewards     = @studio ? Reward.where(studio: @studio, active: true).count : 0
    @total_redemptions  = @studio ? RewardRedemption.where(studio: @studio).count : 0
    @total_deal_claims  = @studio ? DealClaim.where(studio: @studio).count : 0

    @visits_this_week   = @studio ? Visit.where(studio: @studio).where("visited_at >= ?", 1.week.ago).count : 0
    @new_members_this_week = User.where(admin: false).where("created_at >= ?", 1.week.ago).count

    @recent_visits = @studio ? Visit.where(studio: @studio)
                                    .order(visited_at: :desc)
                                    .limit(5)
                                    .includes(:user, :class_config) : []

    @recent_members = User.where(admin: false)
                          .order(created_at: :desc)
                          .limit(5)
  end
end
