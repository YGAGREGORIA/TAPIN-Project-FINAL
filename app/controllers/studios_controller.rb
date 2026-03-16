class StudiosController < ApplicationController
  def show
    @studio = Studio.find_by!(slug: params[:studio_slug])
    @brand = @studio.studio_brand

    return unless user_signed_in?

    if current_user[:admin] || current_user.role == "admin"
      redirect_to admin_dashboard_path, alert: "Studio-Accounts nutzen bitte das Admin-Dashboard."
      return
    end

    result = PhoneCheckInService.new(user: current_user, studio: @studio).call
    redirect_to dashboard_path, result.success? ? { notice: result.message } : { alert: result.message }
  end
end
