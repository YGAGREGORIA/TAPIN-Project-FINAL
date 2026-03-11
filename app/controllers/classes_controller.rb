class ClassesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio

  def index
    @classes = @studio.studio_classes.upcoming
                      .by_type(params[:class_type])
                      .by_teacher(params[:teacher])
                      .by_day(params[:day])

    @class_types = @studio.studio_classes.upcoming.distinct.pluck(:class_type).compact.sort
    @teachers    = @studio.studio_classes.upcoming.distinct.pluck(:teacher_name).compact.sort
  end

  def show
    @studio_class = @studio.studio_classes.find(params[:id])
    @already_booked = current_user.bookings.active.where(studio_class: @studio_class).exists?
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end
end
