class Admin::OnboardingController < Admin::BaseController
  layout "admin_onboarding"

  TOTAL_STEPS = 8
  SITE_ID = "12345"

  def show
    @current_step = current_step
    load_step_data
  end

  VALID_ACTIVATION_CODE = "1234"

  def advance
    # Step 1 requires a valid Mindbody activation code
    if current_step == 1
      if params[:activation_code].to_s.strip != VALID_ACTIVATION_CODE
        redirect_to admin_onboarding_path, alert: "Invalid activation code. Please check your Mindbody account and try again."
        return
      end
    end

    session[:onboarding_step] = [current_step + 1, TOTAL_STEPS].min
    redirect_to admin_onboarding_path
  end

  def goto
    target = params[:step].to_i
    # Only allow jumping to completed steps or current step
    if target.between?(1, current_step)
      session[:onboarding_step] = target
    end
    redirect_to admin_onboarding_path
  end

  # ── Step 7: Branding ──────────────────────────────────────────────────────

  # Saves branding form data and generates AI proposals, then shows the preview.
  def save_branding
    @studio = current_user.studios.first
    @studio_brand = @studio.studio_brand || @studio.build_studio_brand

    if @studio_brand.update(branding_params.merge(raw_extraction: nil))
      proposals = StudioBrandingProposalService.call(@studio_brand)
      if proposals
        @studio_brand.update!(raw_extraction: proposals.to_json)
        session[:onboarding_step] = 7
        redirect_to admin_onboarding_path, notice: "Brand proposals generated!"
      else
        redirect_to admin_onboarding_path,
                    alert: "Couldn't generate a brand proposal right now. Please try again."
      end
    else
      session[:onboarding_step] = 7
      redirect_to admin_onboarding_path, alert: "Please check your inputs and try again."
    end
  end

  # Applies the chosen proposal (0, 1, or 2) and advances to step 8.
  def apply_branding
    @studio = current_user.studios.first
    @studio_brand = @studio.studio_brand

    proposals = load_proposals(@studio_brand)
    unless proposals
      redirect_to admin_onboarding_path, alert: "No proposal found — please regenerate."
      return
    end

    index = params[:proposal_index].to_i.clamp(0, proposals.length - 1)
    chosen = proposals[index].except(:name)

    @studio_brand.update!(chosen.merge(raw_extraction: nil))
    session[:onboarding_step] = 8
    redirect_to admin_onboarding_path, notice: "Your brand is live!"
  end

  # Clears proposals so the form shows again on step 7.
  def regenerate_branding
    @studio = current_user.studios.first
    @studio_brand = @studio.studio_brand
    @studio_brand&.update!(raw_extraction: nil)
    session[:onboarding_step] = 7
    redirect_to admin_onboarding_path
  end

  private

  def current_step
    step = session[:onboarding_step].to_i
    step.between?(1, TOTAL_STEPS) ? step : 1
  end

  def load_step_data
    @studio = current_user.studios.first
    case @current_step
    when 2
      @studio_info = Admin::OnboardingHelper::STUDIO_INFO.merge(
        name: @studio&.name || current_user.studio || "My Studio"
      )
    when 3
      @teachers = Mb::Staff.where(mb_site_id: SITE_ID)
    when 4
      @class_descriptions = Mb::ClassDescription.where(mb_site_id: SITE_ID)
                                                 .includes(klasses: :staff)
    when 5
      @members = Mb::Client.where(mb_site_id: SITE_ID)
    when 7
      @studio_brand = @studio.studio_brand || @studio.build_studio_brand
      @proposals = load_proposals(@studio_brand)
    when 8
      @teacher_count = Mb::Staff.where(mb_site_id: SITE_ID).count
      @class_count = Mb::ClassDescription.where(mb_site_id: SITE_ID).count
      @member_count = Mb::Client.where(mb_site_id: SITE_ID).count
    end
  end

  def branding_params
    params.require(:studio_brand).permit(
      :instagram_url, :facebook_url, :website_url,
      :logo, :philosophy,
      vibe_keywords: []
    )
  end

  def load_proposals(studio_brand)
    return nil if studio_brand&.raw_extraction.blank?
    JSON.parse(studio_brand.raw_extraction, symbolize_names: true)
  rescue JSON::ParserError
    nil
  end
end
