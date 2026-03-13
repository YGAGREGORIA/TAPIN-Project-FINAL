class Admin::NotificationTemplatesController < Admin::BaseController
  def index
    @templates = current_studio.notification_templates
    if @templates.empty?
      seed_default_templates
      @templates = current_studio.notification_templates.reload
    end
  end

  def update
    @template = current_studio.notification_templates.find(params[:id])
    if @template.update(template_params)
      redirect_to admin_notification_templates_path, notice: "Template updated."
    else
      @templates = current_studio.notification_templates
      render :index, status: :unprocessable_entity
    end
  end

  private

  def template_params
    params.require(:notification_template).permit(:title_template, :body_template, :enabled)
  end

  def seed_default_templates
    defaults = [
      { event_type: "reward_unlocked", title_template: "You unlocked a reward!", body_template: "Congratulations [name]! You've earned a free class. Redeem it now!", enabled: true },
      { event_type: "deal_available", title_template: "New deal available!", body_template: "Hey [name], you have a new deal waiting for you. Check it out!", enabled: true },
      { event_type: "booking_reminder", title_template: "Class reminder", body_template: "Hi [name], your class is in 2 hours. See you soon!", enabled: true },
      { event_type: "inactive_user", title_template: "We miss you!", body_template: "Hey [name], it's been a while! Come back for a special offer.", enabled: true },
      { event_type: "deal_expiry", title_template: "Deal expiring soon", body_template: "Hi [name], your deal expires in 3 days. Don't miss out!", enabled: true }
    ]
    defaults.each { |d| current_studio.notification_templates.create!(d) }
  end
end
