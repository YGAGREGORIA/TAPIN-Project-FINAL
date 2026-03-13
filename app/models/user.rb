class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

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

  validates :email, presence: true

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
end
