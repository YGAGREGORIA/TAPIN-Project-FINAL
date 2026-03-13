module Admin
  module Loyalty
    class RewardsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_studio
      before_action :set_reward, only: [:update, :toggle]

      def index
        @rewards = @studio.rewards.order(:id)
        @reward = @studio.rewards.new
      end

      def create
        @reward = @studio.rewards.new(reward_params)

        if @reward.save
          redirect_to admin_loyalty_rewards_path, notice: "Reward created successfully."
        else
          @rewards = @studio.rewards.order(:id)
          render :index, status: :unprocessable_entity
        end
      end

      def update
        if @reward.update(reward_params)
          redirect_to admin_loyalty_rewards_path, notice: "Reward updated successfully."
        else
          @rewards = @studio.rewards.order(:id)
          @reward = @studio.rewards.new
          render :index, status: :unprocessable_entity
        end
      end

      def toggle
        @reward.update(active: !@reward.active)
        redirect_to admin_loyalty_rewards_path, notice: "Reward availability updated."
      end

      private

      def set_studio
        @studio = current_user.studios.first
        redirect_to root_path, alert: "Not authorized." unless @studio
      end

      def set_reward
        @reward = @studio.rewards.find(params[:id])
      end

      def reward_params
        params.require(:reward).permit(:name, :points_cost, :image_url, :description, :reward_type, :active)
      end
    end
  end
end
