class PhoneLoginCode < ApplicationRecord
  CODE_TTL = 10.minutes
  MAX_ATTEMPTS = 5

  belongs_to :studio

  validates :phone_number, presence: true
  validates :expires_at, presence: true
  validates :code_digest, presence: true

  scope :active, -> { where(consumed_at: nil).where("expires_at > ?", Time.current) }

  before_validation :normalize_phone_number

  def self.issue_for!(studio:, phone_number:)
    normalized_phone_number = User.normalize_phone_number(phone_number)
    plain_code = format("%06d", rand(0..999_999))

    active.where(studio: studio, phone_number: normalized_phone_number).delete_all

    record = create!(
      studio: studio,
      phone_number: normalized_phone_number,
      code_digest: digest_for(plain_code),
      expires_at: CODE_TTL.from_now,
      attempts_count: 0
    )

    [record, plain_code]
  end

  def self.digest_for(plain_code)
    Digest::SHA256.hexdigest(plain_code.to_s)
  end

  def verify!(submitted_code)
    increment!(:attempts_count)
    return false if attempts_count > MAX_ATTEMPTS
    return false if expired?
    return false if consumed_at.present?

    if secure_compare(submitted_code)
      touch(:consumed_at)
      true
    else
      false
    end
  end

  def expired?
    expires_at <= Time.current
  end

  private

  def normalize_phone_number
    self.phone_number = User.normalize_phone_number(phone_number)
  end

  def secure_compare(submitted_code)
    ActiveSupport::SecurityUtils.secure_compare(
      code_digest,
      self.class.digest_for(submitted_code)
    )
  end
end
