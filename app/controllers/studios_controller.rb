class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand

    if user_signed_in?
      redirect_to rewards_path(studio_slug: @studio.slug)
      # TODO: redirect to dashboard once Iga builds it
      # redirect_to dashboard_path(studio_slug: @studio.slug)
    end
    # Otherwise render the landing page for new/unauthenticated users
  end
end
