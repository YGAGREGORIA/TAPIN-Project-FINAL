require "test_helper"

class Admin::Loyalty::RewardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "owner@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    @studio = Studio.create!(
      user: @owner,
      name: "Admin Rewards Studio",
      slug: "admin-rewards-studio",
      active: true
    )
    @reward = Reward.create!(
      studio: @studio,
      name: "Free Class",
      points_cost: 100,
      reward_type: "free_class",
      active: true
    )
  end

  # ── auth ────────────────────────────────────────────────────────────────────

  test "redirects unauthenticated user from index" do
    get admin_loyalty_rewards_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from create" do
    post admin_loyalty_rewards_path, params: { reward: { name: "New", reward_type: "free_class" } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from update" do
    patch admin_loyalty_reward_path(@reward), params: { reward: { active: false } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from toggle" do
    patch toggle_admin_loyalty_reward_path(@reward)
    assert_redirected_to new_user_session_path
  end

  test "redirects user with no studio to root" do
    no_studio_user = User.create!(email: "nostudio@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    sign_in no_studio_user
    get admin_loyalty_rewards_path
    assert_redirected_to root_path
  end

  # ── index ───────────────────────────────────────────────────────────────────

  test "owner can access admin rewards index" do
    sign_in @owner
    get admin_loyalty_rewards_path
    assert_response :success
  end

  test "index lists all rewards for the owner's studio" do
    sign_in @owner
    get admin_loyalty_rewards_path
    assert_match @reward.name, response.body
  end

  test "index shows empty state when studio has no rewards" do
    Reward.where(studio: @studio).destroy_all
    sign_in @owner
    get admin_loyalty_rewards_path
    assert_match "No rewards configured yet.", response.body
  end

  test "index does not show rewards from another studio" do
    other_owner = User.create!(email: "other@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio", slug: "other-rewards-studio", active: true)
    other_reward = Reward.create!(studio: other_studio, name: "Other Reward", reward_type: "free_class", active: true)

    sign_in @owner
    get admin_loyalty_rewards_path
    assert_no_match other_reward.name, response.body
  end

  test "index includes a create form" do
    sign_in @owner
    get admin_loyalty_rewards_path
    assert_match "Create reward", response.body
  end

  # ── create ──────────────────────────────────────────────────────────────────

  test "create with valid params redirects with notice" do
    sign_in @owner
    post admin_loyalty_rewards_path,
         params: { reward: { name: "Discount Voucher", points_cost: 50, reward_type: "free_class", active: true } }
    assert_redirected_to admin_loyalty_rewards_path
    assert_equal "Reward created successfully.", flash[:notice]
  end

  test "create persists the new reward to the database" do
    sign_in @owner
    assert_difference -> { @studio.rewards.count }, 1 do
      post admin_loyalty_rewards_path,
           params: { reward: { name: "New Reward", points_cost: 75, reward_type: "free_class", active: false } }
    end
  end

  test "create with invalid params re-renders index with unprocessable_entity" do
    sign_in @owner
    post admin_loyalty_rewards_path, params: { reward: { name: "", reward_type: "free_class" } }
    assert_response :unprocessable_entity
  end

  test "create scopes new reward to the current owner's studio" do
    other_owner = User.create!(email: "other2@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Injected Studio", slug: "injected-studio", active: true)

    sign_in @owner
    post admin_loyalty_rewards_path,
         params: { reward: { name: "Injected", reward_type: "free_class", studio_id: other_studio.id } }
    created = Reward.find_by(name: "Injected")
    assert_equal @studio, created.studio
  end

  # ── update ──────────────────────────────────────────────────────────────────

  test "update with valid params redirects with notice" do
    sign_in @owner
    patch admin_loyalty_reward_path(@reward),
          params: { reward: { name: "Updated Name", points_cost: 200 } }
    assert_redirected_to admin_loyalty_rewards_path
    assert_equal "Reward updated successfully.", flash[:notice]
  end

  test "update persists name and points_cost" do
    sign_in @owner
    patch admin_loyalty_reward_path(@reward),
          params: { reward: { name: "Renamed Reward", points_cost: 150 } }
    @reward.reload
    assert_equal "Renamed Reward", @reward.name
    assert_equal 150, @reward.points_cost
  end

  test "update can disable a reward" do
    sign_in @owner
    patch admin_loyalty_reward_path(@reward), params: { reward: { active: false } }
    assert_equal false, @reward.reload.active
  end

  test "update cannot target a reward belonging to another studio" do
    other_owner = User.create!(email: "other3@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio 3", slug: "other-rewards-studio-3", active: true)
    other_reward = Reward.create!(studio: other_studio, name: "Hands Off", reward_type: "free_class", active: true)

    sign_in @owner
    patch admin_loyalty_reward_path(other_reward), params: { reward: { active: false } }
    assert_response :not_found
  end

  # ── toggle ──────────────────────────────────────────────────────────────────

  test "toggle flips an active reward to inactive" do
    sign_in @owner
    patch toggle_admin_loyalty_reward_path(@reward)
    assert_equal false, @reward.reload.active
  end

  test "toggle flips an inactive reward to active" do
    @reward.update!(active: false)
    sign_in @owner
    patch toggle_admin_loyalty_reward_path(@reward)
    assert_equal true, @reward.reload.active
  end

  test "toggle redirects with notice" do
    sign_in @owner
    patch toggle_admin_loyalty_reward_path(@reward)
    assert_redirected_to admin_loyalty_rewards_path
    assert_equal "Reward availability updated.", flash[:notice]
  end

  test "toggle cannot target a reward belonging to another studio" do
    other_owner = User.create!(email: "other4@admin-rewards.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio 4", slug: "other-rewards-studio-4", active: true)
    other_reward = Reward.create!(studio: other_studio, name: "No Touch", reward_type: "free_class", active: true)

    sign_in @owner
    patch toggle_admin_loyalty_reward_path(other_reward)
    assert_response :not_found
  end
end
