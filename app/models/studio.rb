class Studio < ApplicationRecord
  belongs_to :user

  has_one :studio_brand, dependent: :destroy

  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats

  has_many :deals, dependent: :destroy
  has_many :deal_claims, dependent: :destroy

  has_many :rewards, dependent: :destroy
  has_many :reward_redemptions, through: :rewards

  has_many :class_configs, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :bookings, dependent: :destroy
end
