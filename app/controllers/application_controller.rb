class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :set_studio_brand
  helper_method :current_studio_brand

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def set_studio_brand
    @studio_brand = current_studio_brand
  end

  def current_studio_brand
    return @current_studio_brand if defined?(@current_studio_brand)
    @current_studio_brand = begin
      if current_user&.admin?
        current_user.studios.first&.studio_brand
      elsif current_user
        studio = current_user.visits.order(visited_at: :desc).first&.studio
        studio&.studio_brand
      end
    end
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
