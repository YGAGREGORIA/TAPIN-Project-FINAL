class Admin::AssistantController < Admin::BaseController
  def show
    @chats = current_user.chats.where(studio: current_studio).order(updated_at: :desc)
    @current_chat = if params[:chat_id]
      current_user.chats.find(params[:chat_id])
    else
      @chats.first
    end
    @messages = @current_chat&.messages&.order(:created_at) || []
  end

  def respond
    @chat = if params[:chat_id].present?
      current_user.chats.find(params[:chat_id])
    else
      current_user.chats.create!(studio: current_studio, status: true, title: "New conversation")
    end

    user_message = @chat.messages.create!(
      content: params[:message],
      role: "user"
    )

    response = generate_admin_response(params[:message])

    @chat.messages.create!(
      content: response,
      role: "assistant"
    )

    redirect_to admin_assistant_path(chat_id: @chat.id)
  end

  private

  def generate_admin_response(query)
    q = query.downcase

    if q.include?("close to reward") || q.include?("near reward") || q.include?("almost")
      users_close_to_reward
    elsif q.include?("deal") && (q.include?("suggest") || q.include?("recommend") || q.include?("idea"))
      suggest_deals
    elsif q.include?("retention") || q.include?("improve") || q.include?("churn")
      retention_advice
    elsif q.include?("member") || q.include?("user") || q.include?("customer")
      member_summary
    elsif q.include?("reward") || q.include?("redemption")
      reward_summary
    elsif q.include?("visit") || q.include?("check-in") || q.include?("checkin")
      visit_summary
    else
      general_studio_summary
    end
  end

  def users_close_to_reward
    studio = current_studio
    users_data = User.joins(:visits).where(visits: { studio: studio })
      .group("users.id").having("COUNT(visits.id) % 10 >= 7")
      .select("users.*, COUNT(visits.id) as visit_count")
      .limit(10)

    if users_data.any?
      lines = users_data.map { |u| "- #{u.first_name} #{u.last_name}: #{u.visit_count} visits (#{10 - (u.visit_count.to_i % 10)} more to go)" }
      "Here are members close to their next reward:\n\n#{lines.join("\n")}\n\nConsider sending them a nudge to encourage one more visit!"
    else
      "No members are currently close to a reward milestone. Most are still early in their visit cycles."
    end
  end

  def suggest_deals
    studio = current_studio
    total_members = studio.visits.select(:user_id).distinct.count
    inactive_count = studio.visits.select(:user_id).distinct
      .where("visited_at < ?", 14.days.ago).count

    suggestions = []
    suggestions << "**Re-engagement deal**: #{inactive_count} members haven't visited in 14+ days. A 20% off comeback deal could bring them back." if inactive_count > 0
    suggestions << "**Referral boost**: Increase the referral discount to 60% for a limited time to drive new sign-ups." if total_members < 50
    suggestions << "**Premium class promotion**: Offer double points on premium classes this week to boost attendance."
    suggestions << "**Flash deal**: 15% off for bookings made in the next 48 hours to fill upcoming classes."

    "Based on your studio data:\n\n#{suggestions.join("\n\n")}"
  end

  def retention_advice
    studio = current_studio
    total_visits = studio.visits.count
    unique_visitors = studio.visits.select(:user_id).distinct.count
    avg_visits = unique_visitors > 0 ? (total_visits.to_f / unique_visitors).round(1) : 0

    "**Retention insights for #{studio.name}:**\n\n" \
    "- Total visits: #{total_visits}\n" \
    "- Unique members: #{unique_visitors}\n" \
    "- Avg visits per member: #{avg_visits}\n\n" \
    "**Recommendations:**\n" \
    "- Members with < 3 visits are at highest churn risk — send a personalised deal\n" \
    "- The reward milestone at 10 visits is your biggest retention lever\n" \
    "- Consider a loyalty bonus at visit 5 (halfway point) to keep momentum"
  end

  def member_summary
    studio = current_studio
    total = studio.visits.select(:user_id).distinct.count
    this_week = studio.visits.where("visited_at > ?", 1.week.ago).select(:user_id).distinct.count
    "You have **#{total} total members** at #{studio.name}. **#{this_week}** were active this week."
  end

  def reward_summary
    studio = current_studio
    total_redemptions = studio.reward_redemptions.count
    active = studio.reward_redemptions.where(status: true).count
    "**Rewards summary**: #{total_redemptions} total redemptions, #{active} currently active codes."
  end

  def visit_summary
    studio = current_studio
    today = studio.visits.where("visited_at > ?", Date.current.beginning_of_day).count
    this_week = studio.visits.where("visited_at > ?", 1.week.ago).count
    this_month = studio.visits.where("visited_at > ?", 1.month.ago).count
    "**Check-in summary**: #{today} today, #{this_week} this week, #{this_month} this month."
  end

  def general_studio_summary
    studio = current_studio
    members = studio.visits.select(:user_id).distinct.count
    visits = studio.visits.count
    deals = studio.deal_claims.count
    rewards = studio.reward_redemptions.count

    "**#{studio.name} overview:**\n\n" \
    "- #{members} members\n" \
    "- #{visits} total check-ins\n" \
    "- #{deals} deal claims\n" \
    "- #{rewards} reward redemptions\n\n" \
    "Ask me about members close to rewards, deal suggestions, or retention tips!"
  end
end
