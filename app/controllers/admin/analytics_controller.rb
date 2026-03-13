class Admin::AnalyticsController < Admin::BaseController
  before_action :set_date_range

  # GET /admin/analytics — Member growth & engagement
  def show
    @total_members = User.where(role: :customer).count
    @new_members_this_week = User.where(role: :customer)
                                  .where(created_at: @start_date..@end_date)
                                  .count
    @total_check_ins = studio_visits.count
    @check_ins_in_range = studio_visits.where(visited_at: @start_date..@end_date).count
    @active_members = studio_visits.where(visited_at: @start_date..@end_date)
                                    .distinct.count(:user_id)
    @avg_visits_per_member = @active_members > 0 ? (@check_ins_in_range.to_f / @active_members).round(1) : 0

    # Weekly breakdown for the date range
    @weekly_signups = User.where(role: :customer)
                          .where(created_at: @start_date..@end_date)
                          .group("DATE_TRUNC('week', created_at)")
                          .count
                          .transform_keys { |k| k.strftime("%b %-d") }
    @weekly_checkins = studio_visits.where(visited_at: @start_date..@end_date)
                                     .group("DATE_TRUNC('week', visited_at)")
                                     .count
                                     .transform_keys { |k| k.strftime("%b %-d") }
  end

  # GET /admin/analytics/points — Points economy
  def points
    @total_awarded = studio_visits.where(visited_at: @start_date..@end_date).sum(:points_earned).to_i
    @total_redeemed = studio_redemptions.where(redeemed_at: @start_date..@end_date).sum(:point_spent).to_i
    @in_circulation = User.where(role: :customer).sum(:available_points).to_i

    @top_earners = User.where(role: :customer)
                       .where("available_points > 0")
                       .order(available_points: :desc)
                       .limit(10)

    @points_by_class = studio_visits.where(visited_at: @start_date..@end_date)
                                     .joins(:class_config)
                                     .group("class_configs.class_name")
                                     .sum(:points_earned)
  end

  # GET /admin/analytics/loyalty — Rewards & deals performance
  def loyalty
    # Rewards
    @rewards_created = current_studio.rewards.count
    @total_redemptions = studio_redemptions.where(redeemed_at: @start_date..@end_date).count
    @reward_breakdown = studio_redemptions.where(redeemed_at: @start_date..@end_date)
                                           .joins(:reward)
                                           .group("rewards.name")
                                           .count

    # Deals
    @total_deal_claims = studio_deal_claims.where(claimed_at: @start_date..@end_date).count
    @deal_breakdown = studio_deal_claims.where(claimed_at: @start_date..@end_date)
                                         .joins(:deal)
                                         .group("deals.name")
                                         .count

    # Conversion: claimed deals that were used (status: true → used)
    @deals_used = studio_deal_claims.where(claimed_at: @start_date..@end_date, status: true).count
    @deal_conversion_rate = @total_deal_claims > 0 ? ((@deals_used.to_f / @total_deal_claims) * 100).round(1) : 0

    @rewards_used = studio_redemptions.where(redeemed_at: @start_date..@end_date, status: true).count
    @reward_conversion_rate = @total_redemptions > 0 ? ((@rewards_used.to_f / @total_redemptions) * 100).round(1) : 0
  end

  private

  def set_date_range
    @end_date = Date.current.end_of_day
    @start_date = if params[:start_date].present?
                    Date.parse(params[:start_date]).beginning_of_day
                  else
                    30.days.ago.beginning_of_day
                  end
    @end_date = Date.parse(params[:end_date]).end_of_day if params[:end_date].present?
    @range_label = "#{@start_date.strftime('%b %-d')} — #{@end_date.strftime('%b %-d, %Y')}"
  end

  def studio_visits
    return Visit.none unless current_studio
    Visit.where(studio: current_studio)
  end

  def studio_redemptions
    return RewardRedemption.none unless current_studio
    RewardRedemption.where(studio: current_studio)
  end

  def studio_deal_claims
    return DealClaim.none unless current_studio
    DealClaim.where(studio: current_studio)
  end

  # Simple weekly grouping without groupdate gem
  def group_by_week(relation, column)
    relation.group("DATE_TRUNC('week', #{column})").count
  end
end
