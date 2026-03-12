class Broadcast < ApplicationRecord
  belongs_to :studio

  validates :subject, presence: true
  validates :body, presence: true

  scope :sent, -> { where.not(sent_at: nil) }
  scope :pending, -> { where(sent_at: nil) }

  def sent?
    sent_at.present?
  end

  def delivery_rate
    return 0 if total_sent.nil? || total_sent.zero?
    ((total_delivered.to_f / total_sent) * 100).round(1)
  end
end
