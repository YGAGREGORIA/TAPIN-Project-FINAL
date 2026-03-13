class Admin::DashboardsController < Admin::BaseController
  def show
    @studio = current_studio
    @total_members = User.where(role: :customer).count
    @total_visits = Visit.where(studio: @studio).count if @studio
    @total_deals = Deal.where(studio: @studio).count if @studio
  end
end
