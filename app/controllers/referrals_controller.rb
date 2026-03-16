class ReferralsController < ApplicationController
  before_action :authenticate_user!, only: [ :create, :share ]
  before_action :set_studio

  # POST /s/:studio_slug/referrals
  def create
    @referral = current_user.referrals.build
    if @referral.save
      redirect_to studio_referral_share_path(studio_slug: @studio.slug, id: @referral.id)
    else
      redirect_to studio_landing_path(studio_slug: @studio.slug),
                  alert: @referral.errors.full_messages.first
    end
  end

  # GET /s/:studio_slug/referrals/:id/share
  def share
    @referral = current_user.referrals.find(params[:id])
    @referral_url = studio_referral_landing_url(studio_slug: @studio.slug, code: @referral.referral_code)
  end

  # GET /s/:studio_slug/ref/:code — public, no auth required
  def landing
    @referral = Referral.find_by(referral_code: params[:code], status: "pending")

    if @referral.nil?
      redirect_to studio_landing_path(studio_slug: @studio.slug),
                  alert: "This referral link is no longer valid."
      return
    end

    @referrer = @referral.referrer
    # Store the referral code in session so it persists through sign-up
    session[:referral_code] = @referral.referral_code
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand
  end
end
