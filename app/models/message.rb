class Message < ApplicationRecord
  belongs_to :chat

  has_one_attached :image

  validates :role, presence: true
  validates :content, presence: true
end
