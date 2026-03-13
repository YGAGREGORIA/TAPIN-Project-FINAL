class ApplicationController < ActionController::Base
<<<<<<< HEAD
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
=======
  allow_browser versions: { safari: 16, chrome: 109, firefox: 121, opera: 104, ie: false }
>>>>>>> edadfae12e779043a86bfafd0ffdad17e549b892

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :studio ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :studio ])
  end
end
