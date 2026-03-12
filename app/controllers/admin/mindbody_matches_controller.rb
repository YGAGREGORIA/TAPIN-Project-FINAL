class Admin::MindbodyMatchesController < Admin::BaseController
  def index
    @pending_links = MindbodyLink.where(status: "pending").includes(:user)
    @recent_links = MindbodyLink.where.not(status: "pending").order(updated_at: :desc).limit(20).includes(:user)
  end

  def confirm
    @link = MindbodyLink.find(params[:id])
    @link.update!(status: "linked", linked_at: Time.current)
    redirect_to admin_mindbody_matches_path, notice: "Match confirmed — #{@link.user.first_name} is now linked."
  end

  def reject
    @link = MindbodyLink.find(params[:id])
    @link.update!(status: "standalone")
    redirect_to admin_mindbody_matches_path, notice: "Match rejected — #{@link.user.first_name} marked as standalone."
  end
end
