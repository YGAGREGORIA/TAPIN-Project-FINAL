class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :studio
  belongs_to :studio_class, optional: true

  scope :active, -> { where(status: true) }
  scope :upcoming, -> { active.where("class_time > ?", Time.current).order(:class_time) }
  scope :past, -> { active.where("class_time <= ?", Time.current).order(class_time: :desc) }
end
