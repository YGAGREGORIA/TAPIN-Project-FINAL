class DealClaimsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def create
    deal = @studio.deals.find(params[:id])

    unless deal.eligible_for?(current_user)
      redirect_to deals_path(studio_slug: @studio.slug),
                  alert: "This deal is not available for you."
      return
    end

    @deal_claim = current_user.deal_claims.new(
      deal: deal,
      studio: @studio
    )

    if @deal_claim.save
      redirect_to deal_claim_path(studio_slug: @studio.slug, id: @deal_claim.id),
                  notice: "Deal claimed successfully."
    else
      redirect_to deals_path(studio_slug: @studio.slug),
                  alert: @deal_claim.errors.full_messages.to_sentence
    end
  end

  def show
    @deal_claim = current_user.deal_claims
                              .where(studio: @studio)
                              .find(params[:id])
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
