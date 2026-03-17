class Users::RegistrationsController < Devise::RegistrationsController
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

  def create_studio_for(user)
    return if user.studio.blank?
    return if user.studios.exists?(name: user.studio)

    slug = user.studio.parameterize
    slug = "#{slug}-#{SecureRandom.hex(3)}" if Studio.exists?(slug: slug)

    user.studios.create!(name: user.studio, slug: slug, active: true)
  end
end
