class DealsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def index
    @deals = @studio.deals.active
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
