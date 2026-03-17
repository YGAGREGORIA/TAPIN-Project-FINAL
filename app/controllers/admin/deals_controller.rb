class Admin::DealsController < Admin::BaseController
  def index
    redirect_to admin_rewards_path(tab: "deals")
  end

  def show
    @deal = Deal.find(params[:id])
  end

  def new
    @deal = Deal.new
  end

  def create
    @deal = current_studio.deals.new(deal_params)
    if @deal.save
      redirect_to admin_rewards_path(tab: "deals"), notice: "Deal created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @deal = Deal.find(params[:id])
  end

  def confirm_delete
    @deal = Deal.find(params[:id])
  end

  def update
    @deal = Deal.find(params[:id])
    if @deal.update(deal_params)
      redirect_to admin_rewards_path(tab: "deals"), notice: "Deal updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @deal = Deal.find(params[:id])
    @deal.destroy
    redirect_to admin_rewards_path(tab: "deals"), notice: "Deal deleted."
  end

  def update_referral
    referral_deal = current_studio.deals.find_by(deal_type: "referral")

    unless referral_deal
      redirect_to admin_rewards_path(tab: "deals"), alert: "No referral deal found."
      return
    end

    if referral_deal.update(referral_params)
      redirect_to admin_rewards_path(tab: "deals"), notice: "Referral settings updated."
    else
      redirect_to admin_rewards_path(tab: "deals"), alert: "Failed to update referral settings."
    end
  end

  private

  def deal_params
    params.require(:deal).permit(:name, :deal_type, :discount_percent, :trigger_condition, :usage_limit, :expiry_days, :active)
  end

  def referral_params
    params.require(:deal).permit(:discount_percent, :expiry_days, :usage_limit, :active)
  end
end
