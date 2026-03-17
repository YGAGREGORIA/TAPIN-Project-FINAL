class Admin::BaseController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :require_onboarding_complete!
  helper_method :current_studio

  private

  def current_studio
    @current_studio ||= current_user.studios.first
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: "You are not authorized to access this page."
    end
  end

  # Redirects admins to whichever onboarding step they haven't completed yet.
  # Steps 1 & 2 are required; step 3 (branding) is skippable via "Skip for now".
  # onboarding_step: 0 = not started, 1 = step1 done, 2 = step2 done, 3 = complete/skipped.
  def require_onboarding_complete!
    return unless current_studio
    return if current_studio.onboarding_step >= 3

    redirect_to case current_studio.onboarding_step
                when 0 then step1_admin_onboarding_path
                when 1 then step2_admin_onboarding_path
                when 2 then step3_admin_onboarding_path
                end
  end
end
