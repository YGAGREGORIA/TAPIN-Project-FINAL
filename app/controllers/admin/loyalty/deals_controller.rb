module Admin
  module Loyalty
    class DealsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_studio
      before_action :set_deal, only: [:update, :destroy]

      def index
        @deals = @studio.deals.order(:id)
        @referral_deal = @studio.deals.find_by(trigger_condition: :referral)
        @new_deal = @studio.deals.new
      end

      def create
        @new_deal = @studio.deals.new(create_deal_params)

        if @new_deal.save
          redirect_to admin_loyalty_deals_path, notice: "Deal created successfully."
        else
          @deals = @studio.deals.order(:id)
          @referral_deal = @studio.deals.find_by(trigger_condition: :referral)
          render :index, status: :unprocessable_entity
        end
      end

      def update
        if @deal.update(deal_params)
          redirect_to admin_loyalty_deals_path, notice: "Deal updated successfully."
        else
          @deals = @studio.deals.order(:id)
          @referral_deal = @studio.deals.find_by(trigger_condition: :referral)
          @new_deal = @studio.deals.new
          render :index, status: :unprocessable_entity
        end
      end

      def destroy
        @deal.destroy
        redirect_to admin_loyalty_deals_path, notice: "Deal deleted."
      end

      def update_referral
        @referral_deal = @studio.deals.find_by!(trigger_condition: :referral)

        if @referral_deal.update(referral_params)
          redirect_to admin_loyalty_deals_path, notice: "Referral settings updated successfully."
        else
          @deals = @studio.deals.order(:id)
          @new_deal = @studio.deals.new
          render :index, status: :unprocessable_entity
        end
      end

      private

      def set_studio
        @studio = current_user.studios.first
        redirect_to root_path, alert: "Not authorized." unless @studio
      end

      def set_deal
        @deal = @studio.deals.find(params[:id])
      end

      def create_deal_params
        params.require(:deal).permit(:name, :deal_type, :trigger_condition, :discount_percent, :expiry_days, :active, :usage_limit)
      end

      def deal_params
        params.require(:deal).permit(:active, :discount_percent, :expiry_days)
      end

      def referral_params
        params.require(:deal).permit(:active, :discount_percent, :expiry_days, :usage_limit)
      end
    end
  end
end
