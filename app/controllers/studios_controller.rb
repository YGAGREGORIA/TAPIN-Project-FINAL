class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand

    # Guests → phone login flow
    unless user_signed_in?
      redirect_to studio_phone_login_path(studio_slug: @studio.slug)
      return
    end

    # Logged-in users see the "Tap In" page with a check-in button
  end

  def checkin
    @studio = Studio.find_by!(slug: params[:studio_slug])

    unless user_signed_in?
      redirect_to studio_phone_login_path(studio_slug: @studio.slug)
      return
    end

    create_visit_for(current_user, @studio)
    redirect_to dashboard_path
  end

  private

  def create_visit_for(user, studio)
    visit = user.visits.new(
      studio: studio,
      class_config: studio.class_configs.first,
      visited_at: Time.current,
      points_earned: 1
    )

    if visit.save
      user.recalculate_points! if user.respond_to?(:recalculate_points!)
      flash[:notice] = "You're checked in! Visit counted."
    else
      # 12-hour dedup — visit already counted today
      flash[:notice] = "Welcome back, #{user.display_name}!"
    end
  end
end
