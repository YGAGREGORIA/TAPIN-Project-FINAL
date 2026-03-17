class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand
  end

  def checkin
    @studio = Studio.find_by!(slug: params[:studio_slug])

    if user_signed_in?
      # Logged-in user: create visit directly
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
    else
      # Guest: phone-based check-in
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
        user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
        user.save!
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
        user.recalculate_points! if user.respond_to?(:recalculate_points!)
        redirect_to rewards_path(studio_slug: @studio.slug),
          notice: "Welcome, #{user.first_name}! Your visit was counted."
      else
        redirect_to studio_landing_path(studio_slug: @studio.slug),
          alert: visit.errors.full_messages.to_sentence
      end
    end
  end
end
