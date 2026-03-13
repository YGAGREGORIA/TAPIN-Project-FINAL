class Admin::RewardsController < Admin::BaseController
  def index
    @rewards = current_studio.rewards.order(:name) if current_studio
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
      redirect_to admin_rewards_path, notice: "Reward created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @reward = Reward.find(params[:id])
  end

  def update
    @reward = Reward.find(params[:id])
    if @reward.update(reward_params)
      redirect_to admin_rewards_path, notice: "Reward updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @reward = Reward.find(params[:id])
    @reward.destroy
    redirect_to admin_rewards_path, notice: "Reward deleted."
  end

  private

  def reward_params
    params.require(:reward).permit(:name, :description, :reward_type, :points_cost, :image_url, :active)
  end
end
