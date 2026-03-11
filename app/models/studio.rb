class Studio < ApplicationRecord
  belongs_to :user

  has_one :studio_brand, dependent: :destroy

  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  has_many :deals, dependent: :destroy
  has_many :deal_claims, dependent: :destroy

  has_many :rewards, dependent: :destroy
  has_many :reward_redemptions, dependent: :destroy

  has_many :class_configs, dependent: :destroy
  has_many :studio_classes, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :mindbody_clients, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def free_class_reward
    rewards.find_by(reward_type: :free_class)
  end
end
