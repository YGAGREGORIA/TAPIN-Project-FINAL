class Visit < ApplicationRecord
  include ReferralCompletable
  include MindbodyMatchable
  include NotifiableVisit

  belongs_to :user
  belongs_to :studio
  belongs_to :class_config, optional: true

  validates :visited_at, presence: true
  validate :must_wait_12_hours_between_visits, on: :create

  after_create :auto_start_free_class_card
  after_create :increment_stamp_cards

  private

  def auto_start_free_class_card
    studio.rewards.active.where(reward_type: :free_class).find_each do |reward|
      next if user.stamp_cards.where(reward: reward).where(status: %w[active completed]).exists?
      user.stamp_cards.create!(reward: reward, studio: studio, started_at: Time.current)
    end
  end

  def increment_stamp_cards
    user.stamp_cards.active.where(studio: studio).find_each(&:add_stamp!)
  end

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
