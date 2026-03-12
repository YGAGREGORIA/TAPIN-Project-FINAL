class Admin::DealsController < Admin::BaseController
  # Rajesh: referral settings only
  # Navid: will add index, update, etc. for deals management

  def update_referral
    referral_deal = current_studio.deals.find_by(deal_type: "referral")

    unless referral_deal
      redirect_to admin_deals_path, alert: "No referral deal found."
      return
    end

    if referral_deal.update(referral_params)
      redirect_to admin_deals_path, notice: "Referral settings updated."
    else
      redirect_to admin_deals_path, alert: "Failed to update referral settings."
    end
  end

  private

  def referral_params
    params.require(:deal).permit(:discount_percent, :expiry_days, :usage_limit, :active)
  end
end
