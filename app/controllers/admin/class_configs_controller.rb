class Admin::ClassConfigsController < Admin::BaseController
  def index
    @class_configs = current_studio.class_configs.order(:class_name) if current_studio
    @class_configs ||= ClassConfig.none
  end

  def update
    @class_config = ClassConfig.find(params[:id])
    if @class_config.update(class_config_params)
      redirect_to admin_class_configs_path, notice: "Class config updated."
    else
      redirect_to admin_class_configs_path, alert: @class_config.errors.full_messages.to_sentence
    end
  end

  private

  def class_config_params
    params.require(:class_config).permit(:class_name, :point_value, :is_premium)
  end
end
