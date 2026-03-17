class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_studio_theme

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def set_studio_theme
    return unless user_signed_in? && !current_user.admin?
    return if @studio.present? # already set by the controller (e.g. DashboardsController)
    last_visit = current_user.visits.order(visited_at: :desc).first
    @studio = last_visit ? Studio.includes(:studio_brand).find_by(id: last_visit.studio_id) : nil
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :studio, :first_name, :last_name, :phone, :avatar, :instagram, :facebook, :linkedin ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :studio, :first_name, :last_name, :phone, :avatar, :instagram, :facebook, :linkedin ])
  end

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      dashboard_path
    end
  end
end
