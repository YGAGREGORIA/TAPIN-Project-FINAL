class DashboardController < ApplicationController
  before_action :authenticate_user!

  def show
    @studios_visited = Studio.joins(:visits)
                             .where(visits: { user: current_user })
                             .distinct
                             .includes(:rewards, :deals)

    @upcoming_bookings = current_user.bookings
                                     .where("class_time > ?", Time.current)
                                     .order(:class_time)
                                     .limit(5)
                                     .includes(:studio)

    @recent_visits = current_user.visits
                                 .order(visited_at: :desc)
                                 .limit(5)
                                 .includes(:studio, :class_config)

    @active_deal_claims = current_user.deal_claims
                                      .joins(:deal)
                                      .where(deals: { active: true })
                                      .order(claimed_at: :desc)
                                      .limit(5)
                                      .includes(deal: :studio)

    @available_rewards = @studios_visited.flat_map do |studio|
      studio.rewards.active.select { |reward| reward.redeemable_by?(current_user) }
    end

    @available_deals = @studios_visited.flat_map do |studio|
      claimed_deal_ids = current_user.deal_claims.where(studio: studio).pluck(:deal_id)
      studio.deals.active.reject { |deal| claimed_deal_ids.include?(deal.id) }
    end.first(3)
  end
end
