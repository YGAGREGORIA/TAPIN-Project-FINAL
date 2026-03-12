class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :studio

  has_many :messages, dependent: :destroy

  before_create :set_title

  private

  def set_title
    count = Chat.where(user_id: user_id).count + 1
    self.title ||= "Chat #{count}"
  end
end
