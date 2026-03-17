class Admin::OnboardingsController < ApplicationController
  layout "onboarding"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_studio

  # ── Step 1 (stub — Mindbody integration, owned by other dev) ─────────────
  def step1
    # TODO: implement Mindbody integration step 1
  end

  def complete_step1
    # TODO: validate and save step 1 data, then:
    @studio.update!(onboarding_step: 1)
    redirect_to step2_admin_onboarding_path
  end

  # ── Step 2 (stub — Mindbody integration, owned by other dev) ─────────────
  def step2
    # TODO: implement Mindbody integration step 2
  end

  def complete_step2
    # TODO: validate and save step 2 data, then:
    @studio.update!(onboarding_step: 2)
    redirect_to step3_admin_onboarding_path
  end

  # ── Step 3 — Studio branding ──────────────────────────────────────────────
  def step3
    @studio_brand = @studio.studio_brand || @studio.build_studio_brand
  end

  def complete_step3
    @studio_brand = @studio.studio_brand || @studio.build_studio_brand
    if @studio_brand.update(brand_params)
      @studio.update!(onboarding_step: 3)
      redirect_to admin_dashboard_path, notice: "Your studio is all set. Welcome to TapIn!"
    else
      render :step3, status: :unprocessable_entity
    end
  end

  def skip_step3
    @studio.update!(onboarding_step: 3)
    redirect_to admin_dashboard_path, notice: "Branding skipped — you can complete it anytime from Settings."
  end

  private

  def require_admin!
    redirect_to root_path, alert: "Not authorized." unless current_user&.admin?
  end

  def set_studio
    @studio = current_user.studios.first
    redirect_to root_path, alert: "No studio found for your account." unless @studio
  end

  def brand_params
    params.require(:studio_brand).permit(
      :instagram_url, :facebook_url, :website_url,
      :logo, :philosophy,
      vibe_keywords: []
    )
  end
end
