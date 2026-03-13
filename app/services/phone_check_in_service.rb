class PhoneCheckInService
  Result = Struct.new(:success?, :message, :visit, keyword_init: true)

  def initialize(user:, studio:)
    @user = user
    @studio = studio
  end

  def call
    class_config = @studio.class_configs.first
    return Result.new(success?: false, message: "No class is configured for this studio yet.") if class_config.blank?

    visit = @user.visits.new(
      studio: @studio,
      class_config: class_config,
      visited_at: Time.current,
      points_earned: class_config.point_value
    )

    if visit.save
      @user.increment!(:total_visits) if @user.respond_to?(:total_visits)
      @user.increment!(:total_points, class_config.point_value) if @user.respond_to?(:total_points)
      @user.increment!(:available_points, class_config.point_value) if @user.respond_to?(:available_points)

      Result.new(
        success?: true,
        message: "Herzlichen Glueckwunsch! #{visit.points_earned} Punkte wurden gespeichert.",
        visit: visit
      )
    else
      Result.new(success?: false, message: visit.errors.full_messages.to_sentence, visit: visit)
    end
  end
end
