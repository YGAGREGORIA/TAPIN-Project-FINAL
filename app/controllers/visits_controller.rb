class VisitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def create
    class_config = @studio.class_configs.first

    @visit = current_user.visits.new(
      studio: @studio,
      class_config: class_config,
      visited_at: Time.current
    )

    if @visit.save
      redirect_to rewards_path(studio_slug: @studio.slug),
                  notice: "Your visit was counted successfully."
    else
      redirect_to rewards_path(studio_slug: @studio.slug),
                  alert: @visit.errors.full_messages.to_sentence
    end
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
