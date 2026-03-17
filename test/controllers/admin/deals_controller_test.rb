require "test_helper"

class Admin::DealsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(
      email: "owner@admin-deals-ctrl.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: true,
      role: 1
    )
    @studio = Studio.create!(
      user: @owner,
      name: "Deals Test Studio",
      slug: "deals-test-studio",
      active: true
    )
    @deal = Deal.create!(
      studio: @studio,
      name: "First Visit Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      discount_percent: 20,
      expiry_days: 30
    )
    @referral_deal = Deal.create!(
      studio: @studio,
      name: "Referral Deal",
      deal_type: "discount",
      trigger_condition: "referral",
      active: false,
      discount_percent: 10,
      expiry_days: 14,
      usage_limit: 5
    )
  end

  # ── auth ─────────────────────────────────────────────────────────

  test "redirects unauthenticated user from index" do
    get admin_deals_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from new" do
    get new_admin_deal_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from create" do
    post admin_deals_path, params: { deal: { name: "New", deal_type: "discount", trigger_condition: "first_visit" } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from edit" do
    get edit_admin_deal_path(@deal)
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from update" do
    patch admin_deal_path(@deal), params: { deal: { active: false } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from destroy" do
    delete admin_deal_path(@deal)
    assert_redirected_to new_user_session_path
  end

  test "redirects non-admin user to root" do
    non_admin = User.create!(email: "nonadmin@admin-deals-ctrl.com", password: "Password123", confirmed_at: Time.current)
    sign_in non_admin
    get admin_deals_path
    assert_redirected_to root_path
  end

  # ── index ─────────────────────────────────────────────────────────

  test "index redirects to rewards path with deals tab" do
    sign_in @owner
    get admin_deals_path
    assert_redirected_to admin_rewards_path(tab: "deals")
  end

  # ── show ──────────────────────────────────────────────────────────
  # NOTE: No show.html.erb template exists; only the 404 path is tested.

  test "show returns 404 for non-existent deal" do
    sign_in @owner
    get admin_deal_path(id: 0)
    assert_response :not_found
  end

  # ── new ───────────────────────────────────────────────────────────

  test "new renders the new deal form" do
    sign_in @owner
    get new_admin_deal_path
    assert_response :success
  end

  # ── create ────────────────────────────────────────────────────────

  test "create with valid params redirects to rewards deals tab with notice" do
    sign_in @owner
    post admin_deals_path, params: {
      deal: { name: "New Deal", deal_type: "discount", trigger_condition: "first_visit",
              discount_percent: 15, expiry_days: 7, active: true }
    }
    assert_redirected_to admin_rewards_path(tab: "deals")
    assert_equal "Deal created.", flash[:notice]
  end

  test "create persists new deal scoped to owner's studio" do
    sign_in @owner
    assert_difference -> { @studio.deals.count }, 1 do
      post admin_deals_path, params: {
        deal: { name: "Persisted", deal_type: "discount", trigger_condition: "first_visit" }
      }
    end
  end

  test "create with blank name re-renders new with unprocessable_entity" do
    sign_in @owner
    post admin_deals_path, params: {
      deal: { name: "", deal_type: "discount", trigger_condition: "first_visit" }
    }
    assert_response :unprocessable_entity
  end

  test "create does not save deal with invalid params" do
    sign_in @owner
    assert_no_difference -> { Deal.count } do
      post admin_deals_path, params: {
        deal: { name: "", deal_type: "discount", trigger_condition: "first_visit" }
      }
    end
  end

  # ── edit ──────────────────────────────────────────────────────────

  test "edit renders the edit form" do
    sign_in @owner
    get edit_admin_deal_path(@deal)
    assert_response :success
  end

  test "edit returns 404 for non-existent deal" do
    sign_in @owner
    get edit_admin_deal_path(id: 0)
    assert_response :not_found
  end

  # ── update ────────────────────────────────────────────────────────

  test "update with valid params redirects with notice" do
    sign_in @owner
    patch admin_deal_path(@deal), params: { deal: { active: false, discount_percent: 25, expiry_days: 60 } }
    assert_redirected_to admin_rewards_path(tab: "deals")
    assert_equal "Deal updated.", flash[:notice]
  end

  test "update persists changes" do
    sign_in @owner
    patch admin_deal_path(@deal), params: { deal: { active: false, discount_percent: 25, expiry_days: 60 } }
    @deal.reload
    assert_equal false, @deal.active
    assert_equal 25,    @deal.discount_percent
    assert_equal 60,    @deal.expiry_days
  end

  test "update with blank name re-renders edit with unprocessable_entity" do
    sign_in @owner
    patch admin_deal_path(@deal), params: { deal: { name: "" } }
    assert_response :unprocessable_entity
  end

  test "update does not persist invalid changes" do
    sign_in @owner
    original_name = @deal.name
    patch admin_deal_path(@deal), params: { deal: { name: "" } }
    assert_equal original_name, @deal.reload.name
  end

  # ── confirm_delete ────────────────────────────────────────────────

  test "confirm_delete renders the confirmation page" do
    sign_in @owner
    get confirm_delete_admin_deal_path(@deal)
    assert_response :success
  end

  # ── destroy ───────────────────────────────────────────────────────

  test "destroy removes the deal and redirects with notice" do
    sign_in @owner
    assert_difference -> { @studio.deals.count }, -1 do
      delete admin_deal_path(@deal)
    end
    assert_redirected_to admin_rewards_path(tab: "deals")
    assert_equal "Deal deleted.", flash[:notice]
  end

  test "destroy returns 404 for non-existent deal" do
    sign_in @owner
    delete admin_deal_path(id: 0)
    assert_response :not_found
  end

  # ── update_referral ───────────────────────────────────────────────
  # NOTE: The controller searches by deal_type: "referral", but the Deal
  # enum only defines deal_type: { discount: "discount" }. A referral deal
  # is distinguished by trigger_condition, not deal_type. As a result the
  # find_by always returns nil and the controller always redirects with alert.

  test "update_referral redirects to rewards deals tab with alert when referral deal not found by deal_type" do
    sign_in @owner
    patch update_referral_admin_deals_path, params: {
      deal: { active: true, discount_percent: 15, expiry_days: 21, usage_limit: 3 }
    }
    assert_redirected_to admin_rewards_path(tab: "deals")
    assert_equal "No referral deal found.", flash[:alert]
  end
end
