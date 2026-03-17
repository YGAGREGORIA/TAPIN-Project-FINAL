require "test_helper"

class Admin::RewardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(
      email: "owner@admin-rewards-ctrl.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: true,
      role: 1
    )
    @studio = Studio.create!(
      user: @owner,
      name: "Rewards Test Studio",
      slug: "rewards-test-studio",
      active: true
    )
    @reward = Reward.create!(
      studio: @studio,
      name: "Free Class",
      active: true,
      reward_type: :free_class
    )
  end

  # ── auth ─────────────────────────────────────────────────────────

  test "redirects unauthenticated user from index" do
    get admin_rewards_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from new" do
    get new_admin_reward_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from create" do
    post admin_rewards_path, params: { reward: { name: "New" } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from edit" do
    get edit_admin_reward_path(@reward)
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from update" do
    patch admin_reward_path(@reward), params: { reward: { active: false } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from destroy" do
    delete admin_reward_path(@reward)
    assert_redirected_to new_user_session_path
  end

  test "redirects non-admin user to root" do
    non_admin = User.create!(email: "nonadmin@admin-rewards-ctrl.com", password: "Password123", confirmed_at: Time.current)
    sign_in non_admin
    get admin_rewards_path
    assert_redirected_to root_path
  end

  # ── index ─────────────────────────────────────────────────────────

  test "index renders successfully" do
    sign_in @owner
    get admin_rewards_path
    assert_response :success
  end

  test "index defaults to deals tab" do
    sign_in @owner
    get admin_rewards_path
    assert_match "deals", response.body
  end

  test "index with tab=rewards shows rewards tab" do
    sign_in @owner
    get admin_rewards_path(tab: "rewards")
    assert_response :success
  end

  test "index with invalid tab falls back to deals tab" do
    sign_in @owner
    get admin_rewards_path(tab: "bogus")
    assert_response :success
    # bogus tab is not in allowed list so active_tab defaults to deals
    assert_no_match "bogus", response.body
  end

  test "index lists studio's rewards" do
    sign_in @owner
    get admin_rewards_path(tab: "rewards")
    assert_match @reward.name, response.body
  end

  test "index does not list rewards from another studio" do
    other_owner = User.create!(email: "other@admin-rewards-ctrl.com", password: "Password123", confirmed_at: Time.current, admin: true, role: 1)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio", slug: "other-rewards-studio", active: true)
    other_reward = Reward.create!(studio: other_studio, name: "Other Reward", active: true)

    sign_in @owner
    get admin_rewards_path(tab: "rewards")
    assert_no_match other_reward.name, response.body
  end

  test "index lists studio's deals" do
    deal = Deal.create!(studio: @studio, name: "Summer Deal", deal_type: "discount", trigger_condition: "first_visit", active: true)
    sign_in @owner
    get admin_rewards_path(tab: "deals")
    assert_match deal.name, response.body
  end

  # ── show ──────────────────────────────────────────────────────────
  # NOTE: No show.html.erb template exists; only the 404 path is tested.

  test "show returns 404 for non-existent reward" do
    sign_in @owner
    get admin_reward_path(id: 0)
    assert_response :not_found
  end

  # ── new ───────────────────────────────────────────────────────────

  test "new renders the new reward form" do
    sign_in @owner
    get new_admin_reward_path
    assert_response :success
  end

  # ── create ────────────────────────────────────────────────────────

  test "create with valid params redirects to rewards tab with notice" do
    sign_in @owner
    post admin_rewards_path, params: {
      reward: { name: "Discount Reward", reward_type: "free_class", active: true }
    }
    assert_redirected_to admin_rewards_path(tab: "rewards")
    assert_equal "Reward created.", flash[:notice]
  end

  test "create persists new reward scoped to owner's studio" do
    sign_in @owner
    assert_difference -> { @studio.rewards.count }, 1 do
      post admin_rewards_path, params: {
        reward: { name: "New Reward", reward_type: "free_class", active: true }
      }
    end
  end

  test "create with blank name re-renders new with unprocessable_entity" do
    sign_in @owner
    post admin_rewards_path, params: { reward: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "create does not save reward with blank name" do
    sign_in @owner
    assert_no_difference -> { Reward.count } do
      post admin_rewards_path, params: { reward: { name: "" } }
    end
  end

  # ── edit ──────────────────────────────────────────────────────────

  test "edit renders the edit form" do
    sign_in @owner
    get edit_admin_reward_path(@reward)
    assert_response :success
  end

  test "edit returns 404 for non-existent reward" do
    sign_in @owner
    get edit_admin_reward_path(id: 0)
    assert_response :not_found
  end

  # ── update ────────────────────────────────────────────────────────

  test "update with valid params redirects with notice" do
    sign_in @owner
    patch admin_reward_path(@reward), params: { reward: { name: "Updated Name", active: false } }
    assert_redirected_to admin_rewards_path(tab: "rewards")
    assert_equal "Reward updated.", flash[:notice]
  end

  test "update persists changes" do
    sign_in @owner
    patch admin_reward_path(@reward), params: { reward: { name: "Updated Name", active: false, points_cost: 50 } }
    @reward.reload
    assert_equal "Updated Name", @reward.name
    assert_equal false,          @reward.active
    assert_equal 50,             @reward.points_cost
  end

  test "update with blank name re-renders edit with unprocessable_entity" do
    sign_in @owner
    patch admin_reward_path(@reward), params: { reward: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "update does not persist invalid changes" do
    sign_in @owner
    original_name = @reward.name
    patch admin_reward_path(@reward), params: { reward: { name: "" } }
    assert_equal original_name, @reward.reload.name
  end

  # ── confirm_delete ────────────────────────────────────────────────

  test "confirm_delete renders the confirmation page" do
    sign_in @owner
    get confirm_delete_admin_reward_path(@reward)
    assert_response :success
  end

  test "confirm_delete returns 404 for non-existent reward" do
    sign_in @owner
    get confirm_delete_admin_reward_path(id: 0)
    assert_response :not_found
  end

  # ── destroy ───────────────────────────────────────────────────────

  test "destroy removes the reward and redirects with notice" do
    sign_in @owner
    assert_difference -> { @studio.rewards.count }, -1 do
      delete admin_reward_path(@reward)
    end
    assert_redirected_to admin_rewards_path(tab: "rewards")
    assert_equal "Reward deleted.", flash[:notice]
  end

  test "destroy returns 404 for non-existent reward" do
    sign_in @owner
    delete admin_reward_path(id: 0)
    assert_response :not_found
  end
end
