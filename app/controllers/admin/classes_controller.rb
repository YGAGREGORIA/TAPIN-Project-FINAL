class Admin::ClassesController < Admin::BaseController
  SITE_ID = "12345"

  def index
    @class_descriptions = Mb::ClassDescription.where(mb_site_id: SITE_ID)
                                               .order(:name)

    @upcoming_classes = Mb::Klass.where(mb_site_id: SITE_ID)
                                  .where("start_datetime >= ?", Time.current)
                                  .where(is_canceled: false)
                                  .order(:start_datetime)
                                  .includes(:class_description, :staff)
                                  .limit(50)

    @past_classes = Mb::Klass.where(mb_site_id: SITE_ID)
                              .where("start_datetime < ?", Time.current)
                              .order(start_datetime: :desc)
                              .includes(:class_description, :staff)
                              .limit(50)

    @total_classes = Mb::Klass.where(mb_site_id: SITE_ID).count
    @total_upcoming = Mb::Klass.where(mb_site_id: SITE_ID).where("start_datetime >= ?", Time.current).where(is_canceled: false).count
  end

  def show
    @klass = Mb::Klass.where(mb_site_id: SITE_ID)
                       .includes(:class_description, :staff, :client_visits)
                       .find(params[:id])
  end
end
