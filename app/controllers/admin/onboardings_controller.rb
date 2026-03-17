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

  # ── Step 3 — Studio branding data collection ──────────────────────────────
  def step3
    @studio_brand = @studio.studio_brand || @studio.build_studio_brand
  end

  # Saves the form data, then sends admin to the AI preview before going live.
  # Does NOT mark onboarding complete yet — that happens in apply_branding.
  def complete_step3
    @studio_brand = @studio.studio_brand || @studio.build_studio_brand
    if @studio_brand.update(brand_params.merge(raw_extraction: nil))
      redirect_to preview_branding_admin_onboarding_path
    else
      render :step3, status: :unprocessable_entity
    end
  end

  def skip_step3
    @studio.update!(onboarding_step: 3)
    redirect_to admin_dashboard_path, notice: "Branding skipped — you can complete it anytime from Settings."
  end

  # ── AI branding preview ───────────────────────────────────────────────────

  # Generates (or loads cached) the AI brand proposal and renders the preview.
  def preview_branding
    @studio_brand = @studio.studio_brand
    unless @studio_brand
      redirect_to step3_admin_onboarding_path, alert: "Please complete step 3 first."
      return
    end

    # Use cached proposals if already generated; otherwise call Claude now.
    @proposals = load_or_generate_proposal(@studio_brand)

    if @proposals.nil?
      redirect_to step3_admin_onboarding_path,
                  alert: "Couldn't generate a brand proposal right now. Please try again."
    end
  end

  # Applies the selected AI proposal to studio_brands and marks onboarding complete.
  # Expects params[:proposal_index] (0, 1, or 2) indicating which of the 3 was chosen.
  def apply_branding
    @studio_brand = @studio.studio_brand
    proposals = load_proposals(@studio_brand)

    unless proposals
      redirect_to preview_branding_admin_onboarding_path, alert: "No proposal found — please regenerate."
      return
    end

    index = params[:proposal_index].to_i.clamp(0, proposals.length - 1)
    chosen = proposals[index].except(:name)

    @studio_brand.update!(chosen.merge(raw_extraction: nil))
    @studio.update!(onboarding_step: 3)
    redirect_to admin_dashboard_path, notice: "Your brand is live! Welcome to TapIn."
  end

  # Clears the cached proposal and re-runs the AI.
  def regenerate_branding
    @studio_brand = @studio.studio_brand
    @studio_brand&.update!(raw_extraction: nil)
    redirect_to preview_branding_admin_onboarding_path
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

  def load_or_generate_proposal(studio_brand)
    existing = load_proposals(studio_brand)
    return existing if existing

    proposal = StudioBrandingProposalService.call(studio_brand)
    return nil unless proposal

    # Cache the proposal in raw_extraction as JSON so the apply step can read it.
    studio_brand.update!(raw_extraction: proposal.to_json)
    proposal
  end

  def load_proposals(studio_brand)
    return nil if studio_brand&.raw_extraction.blank?
    JSON.parse(studio_brand.raw_extraction, symbolize_names: true)
  rescue JSON::ParserError
    nil
  end
end
