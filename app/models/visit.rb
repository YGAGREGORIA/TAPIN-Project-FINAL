class Visit < ApplicationRecord
  belongs_to :user
  belongs_to :studio
  belongs_to :class_config

  validates :visited_at, presence: true
  validate :must_wait_12_hours_between_visits, on: :create

  private

  def must_wait_12_hours_between_visits
    last_visit = user.visits
                     .where(studio: studio)
                     .order(visited_at: :desc)
                     .first

    return unless last_visit
    return unless last_visit.visited_at.present?
    return if visited_at >= last_visit.visited_at + 12.hours

    errors.add(:base, "This visit was not counted. You need to wait at least 12 hours before tapping in again.")
  end
end
