class Admin::RewardsController < Admin::BaseController
  def index
    @active_tab = %w[deals rewards].include?(params[:tab]) ? params[:tab] : "rewards"
    @deals = current_studio.deals.includes(:deal_claims).order(:name) if current_studio
    @rewards = current_studio.rewards.includes(:reward_redemptions).order(:name) if current_studio
    @deals ||= Deal.none
    @rewards ||= Reward.none
  end

  def show
    @reward = Reward.find(params[:id])
  end

  def new
    @reward = Reward.new
  end

  def create
    @reward = current_studio.rewards.new(reward_params)
    if @reward.save
      redirect_to admin_rewards_path(tab: "rewards"), notice: "Reward created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @reward = Reward.find(params[:id])
  end

  def confirm_delete
    @reward = Reward.find(params[:id])
  end

  def update
    @reward = Reward.find(params[:id])
    if @reward.update(reward_params)
      redirect_to admin_rewards_path(tab: "rewards"), notice: "Reward updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reward = Reward.find(params[:id])
    @reward.destroy
    redirect_to admin_rewards_path(tab: "rewards"), notice: "Reward deleted."
  end

  private

  def reward_params
    params.require(:reward).permit(:name, :description, :reward_type, :points_cost, :image_url, :active, :visits_required)
  end
end
