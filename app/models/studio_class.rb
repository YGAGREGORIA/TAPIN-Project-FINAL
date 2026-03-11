class StudioClass < ApplicationRecord
  belongs_to :studio
  belongs_to :class_config, optional: true
  has_many :bookings, foreign_key: :studio_class_id, dependent: :nullify

  validates :name, :teacher_name, :scheduled_at, presence: true

  scope :upcoming, -> { where("scheduled_at > ?", Time.current).order(:scheduled_at) }
  scope :by_type, ->(type) { type.present? ? where(class_type: type) : all }
  scope :by_teacher, ->(teacher) { teacher.present? ? where(teacher_name: teacher) : all }
  scope :by_day, ->(day) { day.present? ? where("DATE(scheduled_at AT TIME ZONE 'UTC') = ?", day) : all }

  def spots_available
    capacity - spots_taken
  end

  def full?
    spots_available <= 0
  end

  def booked_by?(user)
    bookings.active.exists?(user: user)
  end
end
