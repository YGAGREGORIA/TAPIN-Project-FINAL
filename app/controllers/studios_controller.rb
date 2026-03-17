class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand

    # Guests → phone login flow
    unless user_signed_in?
      redirect_to studio_phone_login_path(studio_slug: @studio.slug)
    end
  end

  def checkin
    @studio = Studio.find_by!(slug: params[:studio_slug])

    unless user_signed_in?
      redirect_to studio_phone_login_path(studio_slug: @studio.slug)
      return
    end

    visit = current_user.visits.new(
      studio: @studio,
      class_config: @studio.class_configs.first,
      visited_at: Time.current,
      points_earned: @studio.class_configs.first&.point_value || 10
    )

    if visit.save
      current_user.recalculate_points! if current_user.respond_to?(:recalculate_points!)
      redirect_to rewards_path(studio_slug: @studio.slug),
        notice: "You're checked in! Your visit was counted."
    else
      redirect_to studio_landing_path(studio_slug: @studio.slug),
        alert: visit.errors.full_messages.to_sentence
    end
  end
end
