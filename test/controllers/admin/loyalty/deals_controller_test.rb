require "test_helper"

class Admin::Loyalty::DealsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "owner@admin-deals.com", password: "Password123", confirmed_at: Time.current)
    @studio = Studio.create!(
      user: @owner,
      name: "Admin Test Studio",
      slug: "admin-test-studio",
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

  # ── auth ────────────────────────────────────────────────────────

  test "redirects unauthenticated user from index" do
    get admin_loyalty_deals_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from create" do
    post admin_loyalty_deals_path, params: { deal: { name: "New", deal_type: "discount", trigger_condition: "first_visit" } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from update" do
    patch admin_loyalty_deal_path(id: @deal.id), params: { deal: { active: false } }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from destroy" do
    delete admin_loyalty_deal_path(id: @deal.id)
    assert_redirected_to new_user_session_path
  end

  test "redirects user with no studio to root" do
    no_studio_user = User.create!(email: "nostudio@admin-deals.com", password: "Password123", confirmed_at: Time.current)
    sign_in no_studio_user
    get admin_loyalty_deals_path
    assert_redirected_to root_path
  end

  # ── index ────────────────────────────────────────────────────────

  test "owner can access admin deals index" do
    sign_in @owner
    get admin_loyalty_deals_path
    assert_response :success
  end

  test "index lists all deals for the owner's studio" do
    sign_in @owner
    get admin_loyalty_deals_path
    assert_match @deal.name, response.body
  end

  test "index shows the referral settings form when a referral deal exists" do
    sign_in @owner
    get admin_loyalty_deals_path
    assert_match "Referral Settings", response.body
  end

  test "index does not show referral section when no referral deal exists" do
    @referral_deal.destroy
    sign_in @owner
    get admin_loyalty_deals_path
    assert_no_match "Referral Settings", response.body
  end

  test "index shows empty state when the studio has no deals" do
    Deal.where(studio: @studio).destroy_all
    sign_in @owner
    get admin_loyalty_deals_path
    assert_match "No deals configured yet.", response.body
  end

  test "index does not show deals from another studio" do
    other_owner = User.create!(email: "other@admin-deals.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio", slug: "other-admin-studio", active: true)
    other_deal = Deal.create!(studio: other_studio, name: "Other Studio Deal", deal_type: "discount",
                              trigger_condition: "first_visit", active: true)

    sign_in @owner
    get admin_loyalty_deals_path
    assert_no_match other_deal.name, response.body
  end

  # ── update ───────────────────────────────────────────────────────

  test "update with valid params redirects with notice" do
    sign_in @owner
    patch admin_loyalty_deal_path(id: @deal.id),
          params: { deal: { active: false, discount_percent: 15, expiry_days: 7 } }
    assert_redirected_to admin_loyalty_deals_path
    assert_equal "Deal updated successfully.", flash[:notice]
  end

  test "update persists active, discount_percent, and expiry_days" do
    sign_in @owner
    patch admin_loyalty_deal_path(id: @deal.id),
          params: { deal: { active: false, discount_percent: 25, expiry_days: 60 } }
    @deal.reload
    assert_equal false, @deal.active
    assert_equal 25,    @deal.discount_percent
    assert_equal 60,    @deal.expiry_days
  end

  test "update ignores unpermitted params such as name" do
    sign_in @owner
    original_name = @deal.name
    patch admin_loyalty_deal_path(id: @deal.id),
          params: { deal: { name: "Injected Name", active: false } }
    assert_equal original_name, @deal.reload.name
  end

  test "update cannot target a deal belonging to another studio" do
    other_owner = User.create!(email: "other2@admin-deals.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio 2", slug: "other-admin-studio-2", active: true)
    other_deal = Deal.create!(studio: other_studio, name: "Hands Off", deal_type: "discount",
                              trigger_condition: "first_visit", active: true)

    sign_in @owner
    patch admin_loyalty_deal_path(id: other_deal.id), params: { deal: { active: false } }
    assert_response :not_found
  end

  # ── update_referral ──────────────────────────────────────────────
  #
  # NOTE: These tests currently FAIL because the route
  #   PATCH /admin/loyalty/deals/:id
  # is matched before
  #   PATCH /admin/loyalty/deals/referral
  # causing Rails to route to #update with id="referral" instead of
  # #update_referral. Fix: move `patch "deals/referral"` ABOVE
  # `resources :deals` in config/routes.rb.

  test "update_referral with valid params redirects with notice" do
    sign_in @owner
    patch admin_loyalty_deals_referral_path,
          params: { deal: { active: true, discount_percent: 15, expiry_days: 30, usage_limit: 10 } }
    assert_redirected_to admin_loyalty_deals_path
    assert_equal "Referral settings updated successfully.", flash[:notice]
  end

  test "update_referral persists active, discount_percent, expiry_days, and usage_limit" do
    sign_in @owner
    patch admin_loyalty_deals_referral_path,
          params: { deal: { active: true, discount_percent: 15, expiry_days: 21, usage_limit: 3 } }
    @referral_deal.reload
    assert_equal true, @referral_deal.active
    assert_equal 15,   @referral_deal.discount_percent
    assert_equal 21,   @referral_deal.expiry_days
    assert_equal 3,    @referral_deal.usage_limit
  end

  test "update_referral returns 404 when no referral deal exists for the studio" do
    @referral_deal.destroy
    sign_in @owner
    patch admin_loyalty_deals_referral_path, params: { deal: { active: true } }
    assert_response :not_found
  end

  # ── create ───────────────────────────────────────────────────────

  test "create with valid params redirects with notice" do
    sign_in @owner
    post admin_loyalty_deals_path,
         params: { deal: { name: "New Deal", deal_type: "discount", trigger_condition: "first_visit",
                           discount_percent: 15, expiry_days: 7, active: true } }
    assert_redirected_to admin_loyalty_deals_path
    assert_equal "Deal created successfully.", flash[:notice]
  end

  test "create persists the new deal scoped to the owner's studio" do
    sign_in @owner
    assert_difference -> { @studio.deals.count }, 1 do
      post admin_loyalty_deals_path,
           params: { deal: { name: "Persisted Deal", deal_type: "discount", trigger_condition: "first_visit" } }
    end
  end

  test "create with invalid params re-renders index with unprocessable_entity" do
    sign_in @owner
    post admin_loyalty_deals_path, params: { deal: { name: "", deal_type: "discount", trigger_condition: "first_visit" } }
    assert_response :unprocessable_entity
  end

  # ── destroy ──────────────────────────────────────────────────────

  test "destroy removes the deal and redirects with notice" do
    sign_in @owner
    assert_difference -> { @studio.deals.count }, -1 do
      delete admin_loyalty_deal_path(id: @deal.id)
    end
    assert_redirected_to admin_loyalty_deals_path
    assert_equal "Deal deleted.", flash[:notice]
  end

  test "destroy cannot target a deal belonging to another studio" do
    other_owner = User.create!(email: "other5@admin-deals.com", password: "Password123", confirmed_at: Time.current)
    other_studio = Studio.create!(user: other_owner, name: "Other Studio 5", slug: "other-admin-studio-5", active: true)
    other_deal = Deal.create!(studio: other_studio, name: "Do Not Delete", deal_type: "discount",
                              trigger_condition: "first_visit", active: true)

    sign_in @owner
    delete admin_loyalty_deal_path(id: other_deal.id)
    assert_response :not_found
  end
end
