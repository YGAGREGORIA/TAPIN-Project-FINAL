class Admin::CheckinSettingsController < Admin::BaseController
  before_action :set_studio

  def show
    @checkin_url = studio_checkin_url(@studio)
  end

  def update
    old_slug = @studio.slug
    if @studio.update(studio_params)
      redirect_to admin_checkin_settings_path, notice: "Studio slug updated successfully."
    else
      @checkin_url = studio_checkin_url(@studio)
      render :show, status: :unprocessable_entity
    end
  end

  def nfc_guide
  end

  def test
    redirect_to "/s/#{@studio.slug}", notice: "Test check-in triggered — you should see the customer landing page."
  end

  private

  def set_studio
    @studio = current_studio
    redirect_to admin_checkin_settings_path, alert: "No studio found." unless @studio
  end

  def studio_params
    params.require(:studio).permit(:slug)
  end

  def studio_checkin_url(studio)
    "#{request.base_url}/s/#{studio.slug}"
  end
end
