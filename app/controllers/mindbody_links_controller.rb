class MindbodyLinksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def new
    raw = params[:return_to].to_s
    session[:mindbody_return_to] = raw if raw.start_with?("/")
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
