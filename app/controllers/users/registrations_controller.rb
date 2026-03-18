class Users::RegistrationsController < Devise::RegistrationsController
  # Allow updating avatar, name, phone, and social fields without current_password.
  # Only require current_password when changing email or password.
  def update
    self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

    if changing_sensitive_fields?
      super
    else
      resource.assign_attributes(account_update_params.except(:current_password))
      if resource.save
        bypass_sign_in(resource, scope: resource_name) if sign_in_after_change_password?
        set_flash_message!(:notice, :updated)
        redirect_to after_update_path_for(resource)
      else
        clean_up_passwords(resource)
        set_minimum_password_length
        respond_with(resource)
      end
    end
  end

  protected

  def build_resource(hash = {})
    super
    resource.admin = true
    resource.skip_confirmation! if resource.new_record?
  end

  def after_sign_up_path_for(resource)
    create_studio_for(resource)
    admin_onboarding_path
  end

  def after_inactive_sign_up_path_for(resource)
    create_studio_for(resource)
    new_user_session_path
  end

  private

  def changing_sensitive_fields?
    p = account_update_params
    p[:email].present? && p[:email] != resource.email ||
      p[:password].present?
  end

  def create_studio_for(user)
    return if user.studio.blank?
    return if user.studios.exists?(name: user.studio)

    slug = user.studio.parameterize
    slug = "#{slug}-#{SecureRandom.hex(3)}" if Studio.exists?(slug: slug)

    user.studios.create!(name: user.studio, slug: slug, active: true)
  end
end
