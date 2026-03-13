class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand

    if user_signed_in?
      redirect_to dashboard_path
    end
  end

  def checkin
    @studio = Studio.find_by!(slug: params[:studio_slug])
    phone = params[:phone].to_s.gsub(/\D/, "")

    if phone.blank?
      redirect_to studio_landing_path(studio_slug: @studio.slug), alert: "Please enter your phone number."
      return
    end

    user = User.find_by(phone: phone.to_i)

    unless user
      user = User.create!(
        phone: phone.to_i,
        email: "#{phone}@tapin.local",
        password: SecureRandom.hex(16),
        first_name: "New",
        last_name: "Member"
      )
    end

    sign_in(user)

    class_config = @studio.class_configs.first
    visit = user.visits.new(
      studio: @studio,
      class_config: class_config,
      visited_at: Time.current,
      points_earned: class_config&.point_value || 10
    )

    if visit.save
      user.recalculate_points!
      redirect_to dashboard_path,
        notice: "Welcome, #{user.first_name}! Your visit was counted."
    else
      redirect_to dashboard_path,
        alert: visit.errors.full_messages.to_sentence
    end
  end
end
