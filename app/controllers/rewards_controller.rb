class RewardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def index
    @rewards = @studio.rewards.active
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
