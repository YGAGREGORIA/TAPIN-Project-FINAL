class RewardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def index
    @rewards = @studio.rewards.active
    @stamp_cards = current_user.stamp_cards.where(studio: @studio).includes(:reward)
    @active_cards = @stamp_cards.active.index_by(&:reward_id)
    @completed_cards = @stamp_cards.completed.index_by(&:reward_id)
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
