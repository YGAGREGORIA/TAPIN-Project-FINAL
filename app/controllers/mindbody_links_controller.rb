class MindbodyLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def new
    @redirect_back_to = params[:return_to]
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
