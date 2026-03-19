class PhoneSessionsController < ApplicationController
  before_action :set_studio

  # GET /s/:studio_slug/login — show phone input form
  def new
    @brand = @studio.studio_brand
  end

  # POST /s/:studio_slug/login — submit phone, show code screen
  def create
    phone = params[:phone].to_s.gsub(/\D/, "")

    if phone.blank? || phone.length < 6
      redirect_to studio_phone_login_path(studio_slug: @studio.slug),
        alert: "Please enter a valid phone number."
      return
    end

    # Store phone in session for the verify step
    session[:phone_auth_phone] = phone
    session[:phone_auth_studio] = @studio.slug
    session[:phone_auth_code] = rand(1000..9999).to_s

    redirect_to studio_phone_verify_path(studio_slug: @studio.slug)
  end

  # GET /s/:studio_slug/verify — show code input form
  def verify
    @brand = @studio.studio_brand
    @phone = session[:phone_auth_phone]

    unless @phone
      redirect_to studio_phone_login_path(studio_slug: @studio.slug),
        alert: "Please enter your phone number first."
    end
  end

  # POST /s/:studio_slug/verify — validate code, create session
  def confirm
    phone = session[:phone_auth_phone]

    unless phone
      redirect_to studio_phone_login_path(studio_slug: @studio.slug),
        alert: "Session expired. Please enter your phone number again."
      return
    end

    # Accept ANY code (fake verification for now)
    user = User.find_by(phone: phone)

    unless user
      user = User.new(
        phone: phone,
        first_name: "Member",
        last_name: ""
      )
      user.password = SecureRandom.hex(16)
      user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
      user.save!
    end

    # Clear phone auth session data
    session.delete(:phone_auth_phone)
    session.delete(:phone_auth_studio)
    session.delete(:phone_auth_code)

    sign_in(user)

    # Store last studio slug in cookie so logout can redirect back here
    # (session is cleared on sign_out, but cookies survive)
    cookies[:last_studio_slug] = @studio.slug

    # Auto check-in: phone login at a studio = tapping in
    visit = user.visits.new(
      studio: @studio,
      class_config: @studio.class_configs.first,
      visited_at: Time.current,
      points_earned: 1
    )

    if visit.save
      user.recalculate_points! if user.respond_to?(:recalculate_points!)
      redirect_to dashboard_path,
        notice: "Welcome, #{user.display_name}! You're checked in."
    else
      # 12-hour dedup — still go to dashboard
      redirect_to dashboard_path,
        notice: "Welcome back, #{user.display_name}!"
    end
  end

  # DELETE /s/:studio_slug/logout — end session
  def destroy
    sign_out(current_user) if user_signed_in?
    redirect_to studio_landing_path(studio_slug: @studio.slug),
      notice: "You've been logged out."
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
