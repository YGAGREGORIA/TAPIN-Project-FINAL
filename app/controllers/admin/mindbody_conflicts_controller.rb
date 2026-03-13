class Admin::MindbodyConflictsController < Admin::BaseController
  def show
    @link = MindbodyLink.find(params[:id])
    @user = @link.user
    @match_data = @link.match_data || {}
    @mindbody_clients = if @match_data["conflicting_client_ids"].present?
      MindbodyClient.where(mindbody_client_id: @match_data["conflicting_client_ids"])
    else
      MindbodyClient.none
    end
  end
end
