class Admin::OnboardingController < Admin::BaseController
  layout "admin_onboarding"

  TOTAL_STEPS = 7
  SITE_ID = "12345"

  def show
    @current_step = current_step
    load_step_data
  end

  def advance
    session[:onboarding_step] = [current_step + 1, TOTAL_STEPS].min
    redirect_to admin_onboarding_path
  end

  private

  def current_step
    step = session[:onboarding_step].to_i
    step.between?(1, TOTAL_STEPS) ? step : 1
  end

  def load_step_data
    case @current_step
    when 2
      @studio_info = Admin::OnboardingHelper::STUDIO_INFO
    when 3
      @teachers = Mb::Staff.where(mb_site_id: SITE_ID)
    when 4
      @class_descriptions = Mb::ClassDescription.where(mb_site_id: SITE_ID)
                                                 .includes(klasses: :staff)
    when 5
      @members = Mb::Client.where(mb_site_id: SITE_ID)
    end
  end
end
