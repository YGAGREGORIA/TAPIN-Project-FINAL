class Chat < ApplicationRecord
  belongs_to :user
  belongs_to :studio

  has_many :messages, dependent: :destroy
end
