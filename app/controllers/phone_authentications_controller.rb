class PhoneAuthenticationsController < ApplicationController
  before_action :set_studio

  def create
    phone_number = User.normalize_phone_number(params[:phone_number])

    if phone_number.blank?
      redirect_to studio_landing_path(studio_slug: @studio.slug), alert: "Bitte gib deine Telefonnummer ein."
      return
    end

    code_record, plain_code = PhoneLoginCode.issue_for!(studio: @studio, phone_number: phone_number)
    delivery = SmsVerificationSender.new(phone_number: phone_number, code: plain_code).call

    unless delivery.success?
      code_record.destroy
      redirect_to studio_landing_path(studio_slug: @studio.slug), alert: delivery.message
      return
    end

    session[:pending_phone_login_id] = code_record.id

    notice = "Wir haben dir einen Bestätigungscode geschickt."
    notice = "#{notice} #{delivery.message}" if Rails.env.development? || Rails.env.test?

    redirect_to verify_studio_phone_login_path(studio_slug: @studio.slug), notice: notice
  end

  def verify
    unless pending_code.present?
      redirect_to studio_landing_path(studio_slug: @studio.slug), alert: "Bitte starte den Check-in neu."
      return
    end
  end

  def confirm
    code = params[:verification_code].to_s.strip

    if pending_code.blank?
      redirect_to studio_landing_path(studio_slug: @studio.slug), alert: "Dein Code ist abgelaufen. Bitte starte neu."
      return
    end

    unless pending_code.verify!(code)
      redirect_to verify_studio_phone_login_path(studio_slug: @studio.slug), alert: "Der Code ist ungueltig oder abgelaufen."
      return
    end

    user = User.find_or_create_for_phone_login!(pending_code.phone_number)
    sign_in(user)

    result = PhoneCheckInService.new(user: user, studio: @studio).call
    clear_pending_session

    redirect_to dashboard_path, result.success? ? { notice: result.message } : { alert: result.message }
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand
  end

  def pending_code
    return @pending_code if defined?(@pending_code)

    @pending_code = PhoneLoginCode.active.find_by(
      id: session[:pending_phone_login_id],
      studio_id: @studio.id
    )
  end

  def clear_pending_session
    session.delete(:pending_phone_login_id)
  end
end
