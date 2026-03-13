class Admin::BroadcastsController < Admin::BaseController
  def index
    @broadcasts = current_studio.broadcasts.order(created_at: :desc)
    @broadcast = Broadcast.new
  end

  def create
    @broadcast = current_studio.broadcasts.build(broadcast_params)
    if @broadcast.save
      redirect_to admin_broadcasts_path, notice: "Broadcast created."
    else
      @broadcasts = current_studio.broadcasts.order(created_at: :desc)
      render :index, status: :unprocessable_entity
    end
  end

  private

  def broadcast_params
    params.require(:broadcast).permit(:subject, :body, :audience_filter, :channel, :scheduled_at)
  end
end
