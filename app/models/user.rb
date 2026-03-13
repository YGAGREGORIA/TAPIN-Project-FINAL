class User < ApplicationRecord
  OAUTH_PROVIDERS = %i[google_oauth2 facebook apple].freeze
  PASSWORD_COMPLEXITY = /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+\z/

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :lockable, :timeoutable, :omniauthable,
         omniauth_providers: OAUTH_PROVIDERS

  enum :role, { customer: 0, admin: 1 }

  has_many :studios, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :deal_claims, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :reward_redemptions, dependent: :destroy

  has_many :deals, through: :deal_claims

  has_many :referrals, foreign_key: :referrer_id, dependent: :destroy
  has_many :mindbody_links, dependent: :destroy
  has_many :rewards, through: :reward_redemptions
  has_many :push_subscriptions, dependent: :destroy
  has_many :notifications, dependent: :destroy

  before_validation :normalize_email

  validates :email, presence: true
  validate :password_complexity, if: :password_required?

  def self.enabled_omniauth_providers
    OAUTH_PROVIDERS.select { |provider| omniauth_provider_enabled?(provider) }
  end

  def self.omniauth_provider_enabled?(provider)
    config = omniauth_credentials_for(provider)
    config.values.all?(&:present?)
  end

  def self.from_omniauth(auth)
    user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
    user.email = auth.info.email.presence || auth.dig("extra", "raw_info", "email") || user.email
    user.studio = auth.info.name.presence || auth.info.nickname.presence || user.studio
    user.password = Devise.friendly_token.first(24) if user.encrypted_password.blank?
    user.confirmed_at ||= Time.current if user.email.present?
    user.save!
    user
  end

  def visits_count_for(studio)
    visits.where(studio: studio).count
  end

  def reward_redemptions_count_for(studio)
    reward_redemptions.where(studio: studio).count
  end

  def reward_milestones_reached_for(studio)
    visits_count_for(studio) / 10
  end

  def free_class_reward_available_for?(studio)
    reward_milestones_reached_for(studio) > reward_redemptions_count_for(studio)
  end

  def current_visit_progress_for(studio)
    visits_count_for(studio) % 10
  end

  def visits_remaining_for_next_reward(studio)
    count = visits_count_for(studio)
    return 10 if count.zero?

    remainder = count % 10
    remainder.zero? ? 10 : 10 - remainder
  end

  def has_claimed_deal?(deal)
    deal_claims.exists?(deal: deal)
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase.presence
  end

  def password_complexity
    return if password.blank? || password.match?(PASSWORD_COMPLEXITY)

    errors.add(:password, "must include at least one lowercase letter, one uppercase letter, and one number")
  end

  def self.omniauth_credentials_for(provider)
    case provider.to_sym
    when :google_oauth2
      {
        client_id: oauth_value(:google, :client_id, "GOOGLE_CLIENT_ID"),
        client_secret: oauth_value(:google, :client_secret, "GOOGLE_CLIENT_SECRET")
      }
    when :facebook
      {
        client_id: oauth_value(:facebook, :app_id, "FACEBOOK_APP_ID") || oauth_value(:facebook, :client_id, "FACEBOOK_CLIENT_ID"),
        client_secret: oauth_value(:facebook, :app_secret, "FACEBOOK_APP_SECRET") || oauth_value(:facebook, :client_secret, "FACEBOOK_CLIENT_SECRET")
      }
    when :apple
      {
        client_id: oauth_value(:apple, :client_id, "APPLE_CLIENT_ID"),
        team_id: oauth_value(:apple, :team_id, "APPLE_TEAM_ID"),
        key_id: oauth_value(:apple, :key_id, "APPLE_KEY_ID"),
        pem: normalize_pem(oauth_value(:apple, :private_key, "APPLE_PRIVATE_KEY"))
      }
    else
      {}
    end
  end

  def self.oauth_value(provider, credential_key, env_key)
    ENV[env_key].presence || Rails.application.credentials.dig(:oauth, provider, credential_key).presence
  end

  def self.normalize_pem(value)
    value.to_s.gsub('\n', "\n").presence
  end
end
