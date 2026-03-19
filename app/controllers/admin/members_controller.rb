require "csv"

class Admin::MembersController < Admin::BaseController
  ITEMS_PER_PAGE = 6
  CUSTOMER_ROLE = 0

  def index
    @query = params[:q].to_s.strip
    @sort = permitted_sort

    members_scope = User.where(role: CUSTOMER_ROLE)
    members_scope = apply_search(members_scope)

    @total_members = members_scope.count

    @members = apply_sort(members_scope)

    @total_pages = [(@members.count.to_f / ITEMS_PER_PAGE).ceil, 1].max
    @current_page = params.fetch(:page, 1).to_i
    @current_page = 1 if @current_page < 1
    @current_page = @total_pages if @current_page > @total_pages

    offset = (@current_page - 1) * ITEMS_PER_PAGE
    @members = @members.offset(offset).limit(ITEMS_PER_PAGE)
  end

  def show
    @member = User.find(params[:id])
    @recent_visits = @member.visits.order(visited_at: :desc).limit(5)
    @recent_reward_redemptions = @member.reward_redemptions.includes(:reward).latest_first.limit(5)
    @recent_deal_claims = @member.deal_claims.includes(:deal).latest_first.limit(5)
    @available_rewards = current_studio ? current_studio.rewards.where(active: true).order(:name) : Reward.none
  end

  def export
    @members = User.where(role: CUSTOMER_ROLE).order(:last_name, :first_name)
    respond_to do |format|
      format.csv do
        send_data generate_members_csv(@members),
                  filename: "members-#{Date.today}.csv",
                  type: "text/csv; charset=utf-8"
      end
      format.html { redirect_to admin_members_path }
    end
  end

  private

  def permitted_sort
    allowed = %w[none date-newest date-oldest points-high points-low visits-high visits-low]
    allowed.include?(params[:sort]) ? params[:sort] : "date-newest"
  end

  def apply_search(scope)
    return scope if @query.blank?

    like_query = "%#{@query.downcase}%"

    scope.where(
      "LOWER(COALESCE(first_name, '') || ' ' || COALESCE(last_name, '')) LIKE :query
       OR LOWER(COALESCE(email, '')) LIKE :query
       OR COALESCE(phone, '') LIKE :digits",
      query: like_query,
      digits: "%#{@query}%"
    )
  end

  def apply_sort(scope)
    case @sort
    when "date-oldest"
      scope.order(created_at: :asc)
    when "points-high"
      scope.order(available_points: :desc, created_at: :desc)
    when "points-low"
      scope.order(available_points: :asc, created_at: :desc)
    when "visits-high"
      scope.order(total_visits: :desc, created_at: :desc)
    when "visits-low"
      scope.order(total_visits: :asc, created_at: :desc)
    else
      scope.order(created_at: :desc)
    end
  end

  def generate_members_csv(members)
    CSV.generate(headers: true) do |csv|
      csv << ["First Name", "Last Name", "Email", "Phone", "Available Points", "Total Points", "Total Visits", "Joined At"]

      members.find_each do |member|
        csv << [
          member.first_name,
          member.last_name,
          member.email,
          member.phone,
          member.available_points.to_i,
          member.total_points.to_i,
          member.total_visits.to_i,
          member.created_at&.iso8601
        ]
      end
    end
  end
end
