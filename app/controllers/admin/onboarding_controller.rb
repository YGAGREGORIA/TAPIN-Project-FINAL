class Admin::OnboardingController < Admin::BaseController
  before_action :set_studio
  before_action :load_state

  STEP_IDS = (1..7).to_a.freeze
  STEP_DEFINITIONS = [
    { number: 1, label: "Connect Mindbody", icon: "fa-cloud" },
    { number: 2, label: "Import Studio Information", icon: "fa-building" },
    { number: 3, label: "Import Teachers", icon: "fa-users" },
    { number: 4, label: "Import Classes", icon: "fa-calendar" },
    { number: 5, label: "Import Members", icon: "fa-user-plus" },
    { number: 6, label: "Check-in Setup", icon: "fa-qrcode" },
    { number: 7, label: "Final Setup", icon: "fa-check-circle" }
  ].freeze

  def show
    @current_step = normalized_step(params[:step] || @state["current_step"]) || 1
    @completed_steps = Array(@state["completed_steps"]).map(&:to_i)
    @step_definitions = STEP_DEFINITIONS

    @mindbody_ready = @studio.mindbody_site_id.present? || @studio.mindbody_api_key.present? || @studio.mindbody_clients.exists?
    @checkin_url = "#{request.base_url}/s/#{@studio.slug}"

    @teacher_rows = @studio.studio_classes.where.not(teacher_name: [ nil, "" ])
                                 .group(:teacher_name)
                                 .order(Arel.sql("COUNT(*) DESC"))
                                 .count
                                 .map do |teacher_name, class_count|
      {
        name: teacher_name,
        class_count: class_count,
        focus: @studio.studio_classes.where(teacher_name: teacher_name).where.not(class_type: [ nil, "" ]).limit(2).pluck(:class_type).map(&:titleize).presence || [ "Studio Classes" ]
      }
    end

    @class_rows = @studio.studio_classes.order(:scheduled_at).limit(6)
    @member_rows = @studio.mindbody_clients.order(:first_name, :last_name).limit(6)
  end

  def advance
    step = normalized_step(params[:step]) || normalized_step(@state["current_step"]) || 1

    @state["completed_steps"] = (Array(@state["completed_steps"]).map(&:to_i) | [ step ]).sort
    @state["mindbody_connected"] = true if step == 1
    @state["current_step"] = [ step + 1, STEP_IDS.max ].min

    persist_state!
    redirect_to admin_onboarding_path(step: @state["current_step"]), notice: step_notice(step)
  end

  def go_to_step
    step = normalized_step(params[:step]) || 1
    @state["current_step"] = step
    persist_state!

    redirect_to admin_onboarding_path(step: step)
  end

  def reset
    session.delete(:admin_onboarding)
    redirect_to admin_onboarding_path, notice: "Onboarding progress was reset."
  end

  private

  def set_studio
    @studio = current_studio
    redirect_to admin_dashboard_path, alert: "Create a studio first to start onboarding." unless @studio
  end

  def load_state
    @state = session[:admin_onboarding].is_a?(Hash) ? session[:admin_onboarding] : {}
  end

  def persist_state!
    session[:admin_onboarding] = @state
  end

  def normalized_step(value)
    step = value.to_i
    STEP_IDS.include?(step) ? step : nil
  end

  def step_notice(step)
    case step
    when 1 then "Mindbody connection saved for onboarding."
    when 2 then "Studio information marked as imported."
    when 3 then "Teachers imported into your setup flow."
    when 4 then "Classes imported into your setup flow."
    when 5 then "Members imported into your setup flow."
    when 6 then "Check-in setup confirmed."
    else "Setup complete."
    end
  end
end
