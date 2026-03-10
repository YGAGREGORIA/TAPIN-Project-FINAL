class ClassConfig < ApplicationRecord
  belongs_to :studio

  has_many :visits, dependent: :destroy
end
