class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
  :recoverable, :rememberable, :validatable

  has_many :studios, dependent: :destroy
  has_many :chats, dependent: :destroy
  has_many :messages, through: :chats
  has_many :deal_claims, dependent: :destroy
  has_many :visits, dependent: :destroy
  has_many :bookings, dependent: :destroy
  has_many :reward_redemptions, dependent: :destroy

  has_many :deals, through: :deal_claims
  has_many :rewards, through: :reward_redemptions
end
