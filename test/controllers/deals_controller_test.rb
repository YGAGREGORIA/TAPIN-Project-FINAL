require "test_helper"

class DealsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "owner@deals-ctrl.com", password: "password")
    @studio = Studio.create!(
      user: @owner,
      name: "Deals Ctrl Studio",
      slug: "deals-ctrl-studio",
      active: true
    )
    @user = User.create!(email: "user@deals-ctrl.com", password: "password")
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 701,
      class_name: "Deals Test Class",
      point_value: 10,
      is_premium: false
    )
    @deal = Deal.create!(
      studio: @studio,
      name: "First Visit Discount",
      deal_type: "discount",
      discount_percent: 20,
      trigger_condition: "first_visit",
      active: true
    )
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

  # --- auth ---

  test "redirects unauthenticated user to sign in" do
    get "/s/#{@studio.slug}/deals"
    assert_redirected_to new_user_session_path
  end

  test "returns 404 for unknown studio slug" do
    sign_in @user
    get "/s/unknown-slug-xyz/deals"
    assert_response :not_found
  end

  # --- active/inactive filtering ---

  test "active deals are shown" do
    sign_in @user
    get "/s/#{@studio.slug}/deals"
    assert_response :success
    assert_match @deal.name, response.body
  end

  test "inactive deals are not shown" do
    inactive = Deal.create!(studio: @studio, name: "Hidden Deal", deal_type: "discount",
                            trigger_condition: "first_visit", active: false)
    sign_in @user
    get "/s/#{@studio.slug}/deals"
    assert_no_match inactive.name, response.body
  end

  # --- Criteria 1: claim button appears after first visit ---

  test "claim button is NOT shown before any visit" do
    sign_in @user
    get "/s/#{@studio.slug}/deals"
    assert_no_match "Claim deal", response.body
    assert_match "This deal will unlock after your first visit.", response.body
  end

  test "claim button IS shown after at least one visit" do
    sign_in @user
    create_visit_for(@user)
    get "/s/#{@studio.slug}/deals"
    assert_match "Claim deal", response.body
  end

  # --- Criteria 2: "You already claimed this deal" appears after claiming ---

  test "shows 'You already claimed this deal' after the deal has been claimed" do
    sign_in @user
    create_visit_for(@user)
    DealClaim.create!(user: @user, deal: @deal, studio: @studio)

    get "/s/#{@studio.slug}/deals"
    assert_match "You already claimed this deal.", response.body
    assert_no_match "Claim deal", response.body
  end
end
