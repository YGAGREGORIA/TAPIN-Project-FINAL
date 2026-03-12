require "test_helper"

class DealTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@deal-test.com", password: "password")
    @studio = Studio.create!(
      user: @owner,
      name: "Deal Test Studio",
      slug: "deal-test-studio",
      active: true
    )
    @user = User.create!(email: "user@deal-test.com", password: "password")
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 801,
      class_name: "Deal Test Class",
      point_value: 10,
      is_premium: false
    )
  end

  def build_deal(attrs = {})
    Deal.new({
      studio: @studio,
      name: "Free First Class",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true
    }.merge(attrs))
  end

  def create_deal(attrs = {})
    build_deal(attrs).tap(&:save!)
  end

  def create_visit_for(user)
    Visit.create!(
      user: user,
      studio: @studio,
      class_config: @class_config,
      visited_at: 2.days.ago,
      points_earned: 10
    )
  end

  # --- validations ---

  test "valid deal saves" do
    assert build_deal.valid?
  end

  test "name is required" do
    deal = build_deal(name: nil)
    assert_not deal.valid?
    assert_includes deal.errors[:name], "can't be blank"
  end

  # --- scope :active ---

  test "active scope returns only active deals" do
    active_deal   = create_deal(active: true,  name: "Active Deal")
    inactive_deal = create_deal(active: false, name: "Inactive Deal")

    active_ids = @studio.deals.active.pluck(:id)
    assert_includes     active_ids, active_deal.id
    assert_not_includes active_ids, inactive_deal.id
  end

  # --- eligibility_status_for ---

  test "returns :not_logged_in for nil user" do
    assert_equal :not_logged_in, create_deal.eligibility_status_for(nil)
  end

  test "returns :inactive when deal is not active" do
    deal = create_deal(active: false)
    create_visit_for(@user)
    assert_equal :inactive, deal.eligibility_status_for(@user)
  end

  test "returns :already_claimed when user has already claimed the deal" do
    deal = create_deal
    create_visit_for(@user)
    DealClaim.create!(user: @user, deal: deal, studio: @studio)
    assert_equal :already_claimed, deal.eligibility_status_for(@user)
  end

  test "returns :not_unlocked_yet for first_visit trigger when user has no visits" do
    deal = create_deal(trigger_condition: "first_visit")
    assert_equal :not_unlocked_yet, deal.eligibility_status_for(@user)
  end

  test "returns :eligible for first_visit trigger when user has at least one visit" do
    deal = create_deal(trigger_condition: "first_visit")
    create_visit_for(@user)
    assert_equal :eligible, deal.eligibility_status_for(@user)
  end

  test "returns :not_eligible for unknown trigger_condition" do
    deal = create_deal(trigger_condition: "unknown_condition")
    create_visit_for(@user)
    assert_equal :not_eligible, deal.eligibility_status_for(@user)
  end

  test "returns :not_unlocked_yet when visits are at a different studio" do
    other_studio = Studio.create!(
      user: @owner,
      name: "Other Studio",
      slug: "other-studio-deal",
      active: true
    )
    other_config = ClassConfig.create!(
      studio: other_studio,
      mindbody_class_id: 802,
      class_name: "Other Class",
      point_value: 10,
      is_premium: false
    )
    Visit.create!(
      user: @user,
      studio: other_studio,
      class_config: other_config,
      visited_at: 2.days.ago,
      points_earned: 10
    )

    deal = create_deal(trigger_condition: "first_visit")
    assert_equal :not_unlocked_yet, deal.eligibility_status_for(@user)
  end

  # --- eligible_for? (delegates to eligibility_status_for) ---

  test "eligible_for? returns true when status is :eligible" do
    deal = create_deal
    create_visit_for(@user)
    assert deal.eligible_for?(@user)
  end

  test "eligible_for? returns false for any non-eligible status" do
    deal = create_deal
    assert_not deal.eligible_for?(@user) # :not_unlocked_yet
  end
end
