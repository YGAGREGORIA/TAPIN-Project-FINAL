module ReferralCompletable
  extend ActiveSupport::Concern

  included do
    after_create :complete_referral_if_first_visit
  end

  private

  def complete_referral_if_first_visit
    return unless first_visit_at_studio?

    referral = pending_referral_for_user
    return unless referral

    referral.complete!(user)
    grant_referral_deals(referral)
  end

  def first_visit_at_studio?
    user.visits.where(studio: studio).count == 1
  end

  def pending_referral_for_user
    code = user.referred_by
    return nil if code.blank?

    Referral.find_by(referral_code: code, status: "pending")
  end

  def grant_referral_deals(referral)
    referral_deal = studio.deals.find_by(trigger_condition: "referral")
    return unless referral_deal

    # 50% off for the referred friend
    DealClaim.create!(user: user, deal: referral_deal)

    # 50% off for the referrer
    DealClaim.create!(user: referral.referrer, deal: referral_deal)
  end
end
