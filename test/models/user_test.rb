require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@user-test.com", password: "password")
    @studio = Studio.create!(
      user: @owner,
      name: "User Test Studio",
      slug: "user-test-studio",
      active: true
    )
    @user = User.create!(email: "subject@user-test.com", password: "password")
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 900,
      class_name: "Test Class",
      point_value: 10,
      is_premium: false
    )
    @reward = Reward.create!(
      studio: @studio,
      name: "Free Class",
      reward_type: :free_class,
      active: true
    )
  end

  # Creates n visits spaced 2 days apart so the 12-hour rule never blocks them.
  def add_visits(count)
    count.times do |i|
      Visit.create!(
        user: @user,
        studio: @studio,
        class_config: @class_config,
        visited_at: ((count - i) * 2).days.ago,
        points_earned: 10
      )
    end
  end

  def add_redemption
    RewardRedemption.create!(
      user: @user,
      reward: @reward,
      studio: @studio,
      redeemed_at: 1.day.ago,
      expiry_days: 30,
      point_spent: 0,
      status: true
    )
  end

  # --- fewer than 10 visits → no reward ---

  test "0 visits — no reward available" do
    assert_not @user.free_class_reward_available_for?(@studio)
  end

  test "9 visits — no reward available" do
    add_visits(9)
    assert_not @user.free_class_reward_available_for?(@studio)
  end

  # --- 10th visit triggers reward ---

  test "exactly 10 visits — reward becomes available" do
    add_visits(10)
    assert @user.free_class_reward_available_for?(@studio)
  end

  # --- second reward only after 20 visits ---

  test "19 visits with 1 redemption — no second reward yet" do
    add_visits(19)
    add_redemption
    assert_not @user.free_class_reward_available_for?(@studio)
  end

  test "20 visits with 1 redemption — second reward available" do
    add_visits(20)
    add_redemption
    assert @user.free_class_reward_available_for?(@studio)
  end

  test "20 visits with 2 redemptions — no third reward yet" do
    add_visits(20)
    add_redemption
    add_redemption
    assert_not @user.free_class_reward_available_for?(@studio)
  end
end
