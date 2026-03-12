require "test_helper"

class DealClaimTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@claim-test.com", password: "password")
    @studio = Studio.create!(
      user: @owner,
      name: "Claim Test Studio",
      slug: "claim-test-studio",
      active: true
    )
    @user = User.create!(email: "user@claim-test.com", password: "password")
    @deal = Deal.create!(
      studio: @studio,
      name: "Test Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      expiry_days: 30
    )
  end

  def build_claim(attrs = {})
    DealClaim.new({ user: @user, deal: @deal, studio: @studio }.merge(attrs))
  end

  def create_claim(attrs = {})
    build_claim(attrs).tap(&:save!)
  end

  # --- validations ---

  test "valid claim saves with auto-generated code" do
    claim = build_claim
    assert claim.valid?
    assert claim.save
  end

  test "code uniqueness is enforced" do
    create_claim
    duplicate = build_claim
    duplicate.code = DealClaim.last.code
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:code], "has already been taken"
  end

  # --- set_defaults callback ---

  test "code is auto-generated with DEAL- prefix on create" do
    claim = create_claim
    assert_match(/\ADEAL-[A-Z0-9]{8}\z/, claim.code)
  end

  test "claimed_at is set automatically on create" do
    freeze_time do
      claim = create_claim
      assert_in_delta Time.current.to_i, claim.claimed_at.to_i, 1
    end
  end

  test "status defaults to true on create" do
    claim = create_claim
    assert claim.status
  end

  test "studio is inherited from deal when not explicitly set" do
    claim = DealClaim.create!(user: @user, deal: @deal)
    assert_equal @studio, claim.studio
  end

  test "two claims get different codes" do
    claim1 = create_claim
    other_user = User.create!(email: "other@claim-test.com", password: "password")
    other_deal = Deal.create!(
      studio: @studio,
      name: "Another Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true
    )
    claim2 = DealClaim.create!(user: other_user, deal: other_deal, studio: @studio)
    assert_not_equal claim1.code, claim2.code
  end

  # --- expires_at ---

  test "expires_at returns nil when deal has no expiry_days" do
    deal_no_expiry = Deal.create!(
      studio: @studio,
      name: "No Expiry Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      expiry_days: nil
    )
    claim = DealClaim.create!(user: @user, deal: deal_no_expiry, studio: @studio)
    assert_nil claim.expires_at
  end

  test "expires_at returns claimed_at plus expiry_days" do
    claim = create_claim
    expected = claim.claimed_at + 30.days
    assert_equal expected, claim.expires_at
  end

  # --- expired? ---

  test "expired? returns false when there is no expiry" do
    deal_no_expiry = Deal.create!(
      studio: @studio,
      name: "No Expiry Deal 2",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      expiry_days: nil
    )
    claim = DealClaim.create!(user: @user, deal: deal_no_expiry, studio: @studio)
    assert_not claim.expired?
  end

  test "expired? returns false when expiry is in the future" do
    claim = create_claim
    assert_not claim.expired?
  end

  test "expired? returns true when expiry is in the past" do
    claim = create_claim
    claim.update_column(:claimed_at, 31.days.ago)
    assert claim.expired?
  end

  # --- scopes ---

  test "latest_first scope orders by created_at descending" do
    claim1 = create_claim
    other_user = User.create!(email: "scope@claim-test.com", password: "password")
    other_deal = Deal.create!(
      studio: @studio,
      name: "Scope Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true
    )
    claim2 = DealClaim.create!(user: other_user, deal: other_deal, studio: @studio)

    ids = DealClaim.latest_first.pluck(:id)
    assert ids.index(claim2.id) < ids.index(claim1.id)
  end
end
