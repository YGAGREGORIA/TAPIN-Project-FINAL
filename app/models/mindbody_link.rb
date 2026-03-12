class MindbodyLink < ApplicationRecord
  belongs_to :user

  validates :mindbody_client_id, presence: true, if: :linked?

  scope :linked, -> { where(status: "linked") }
  scope :pending, -> { where(status: "pending") }

  def linked?
    status == "linked"
  end

  def link!(client_id)
    update!(
      mindbody_client_id: client_id,
      status: "linked",
      linked_at: Time.current
    )
  end
end
