class BookingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_studio
  before_action :set_booking, only: [ :show, :destroy ]

  def index
    @upcoming_bookings = current_user.bookings.where(studio: @studio).upcoming
    @past_bookings     = current_user.bookings.where(studio: @studio).past.limit(10)
  end

  def show
  end

  def create
    @studio_class = @studio.studio_classes.find(params[:id])

    if @studio_class.booked_by?(current_user)
      redirect_to class_path(studio_slug: @studio.slug, id: @studio_class.id),
                  alert: "You've already booked this class."
      return
    end

    if @studio_class.full?
      redirect_to class_path(studio_slug: @studio.slug, id: @studio_class.id),
                  alert: "Sorry, this class is full."
      return
    end

    @booking = current_user.bookings.build(
      studio:       @studio,
      studio_class: @studio_class,
      class_name:   @studio_class.name,
      class_time:   @studio_class.scheduled_at,
      booked_at:    Time.current,
      status:       true
    )

    if @booking.save
      @studio_class.increment!(:spots_taken)
      redirect_to booking_path(studio_slug: @studio.slug, id: @booking.id),
                  notice: "You're booked!"
    else
      redirect_to class_path(studio_slug: @studio.slug, id: @studio_class.id),
                  alert: "Unable to complete booking. Please try again."
    end
  end

  def destroy
    if @booking.update(status: false)
      if @booking.studio_class.present?
        @booking.studio_class.decrement!(:spots_taken)
      end
      redirect_to bookings_path(studio_slug: @studio.slug),
                  notice: "Booking cancelled."
    else
      redirect_to booking_path(studio_slug: @studio.slug, id: @booking.id),
                  alert: "Unable to cancel booking."
    end
  end

  private

  def set_studio
    @studio = Studio.find_by!(slug: params[:studio_slug])
  end

  def set_booking
    @booking = current_user.bookings.find(params[:id])
  end
end
