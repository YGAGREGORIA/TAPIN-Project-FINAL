class Deal < ApplicationRecord
  belongs_to :studio
  has_many :deal_claims, dependent: :destroy

  validates :name, presence: true

  scope :active, -> { where(active: true) }

  def eligible_for?(user)
    eligibility_status_for(user) == :eligible
  end

  def eligibility_status_for(user)
    return :not_logged_in unless user
    return :inactive unless active?
    return :already_claimed if user.has_claimed_deal?(self)

    case trigger_condition
    when "first_visit"
      user.visits_count_for(studio) >= 1 ? :eligible : :not_unlocked_yet
    else
      :not_eligible
    end
  end
end
