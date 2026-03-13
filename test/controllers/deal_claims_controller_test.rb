require "test_helper"

class DealClaimsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(email: "owner@claims-ctrl.com", password: "Password123", confirmed_at: Time.current)
    @studio = Studio.create!(
      user: @owner,
      name: "Claims Ctrl Studio",
      slug: "claims-ctrl-studio",
      active: true
    )
    @user = User.create!(email: "user@claims-ctrl.com", password: "Password123", confirmed_at: Time.current)
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 701,
      class_name: "Claims Test Class",
      point_value: 10,
      is_premium: false
    )
    @deal = Deal.create!(
      studio: @studio,
      name: "Ctrl Test Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      expiry_days: 30
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

  # --- create ---

  test "redirects unauthenticated user to sign in on claim" do
    post "/s/#{@studio.slug}/deals/#{@deal.id}/claim"
    assert_redirected_to new_user_session_path
  end

  test "creates deal claim when user is eligible" do
    sign_in @user
    create_visit_for(@user)

    assert_difference "DealClaim.count", 1 do
      post "/s/#{@studio.slug}/deals/#{@deal.id}/claim"
    end

    claim = DealClaim.last
    assert_redirected_to "/s/#{@studio.slug}/deal_claims/#{claim.id}"
    assert_equal @user, claim.user
    assert_equal @deal, claim.deal
  end

  test "redirects with alert when user is not eligible" do
    sign_in @user
    # No visit — does not satisfy first_visit trigger

    assert_no_difference "DealClaim.count" do
      post "/s/#{@studio.slug}/deals/#{@deal.id}/claim"
    end

    assert_redirected_to "/s/#{@studio.slug}/deals"
    assert_equal "This deal is not available for you.", flash[:alert]
  end

  test "does not allow claiming the same deal twice" do
    sign_in @user
    create_visit_for(@user)
    DealClaim.create!(user: @user, deal: @deal, studio: @studio)

    assert_no_difference "DealClaim.count" do
      post "/s/#{@studio.slug}/deals/#{@deal.id}/claim"
    end

    assert_redirected_to "/s/#{@studio.slug}/deals"
  end

  # --- show ---

  test "redirects unauthenticated user to sign in on show" do
    claim = DealClaim.create!(user: @user, deal: @deal, studio: @studio)
    get "/s/#{@studio.slug}/deal_claims/#{claim.id}"
    assert_redirected_to new_user_session_path
  end

  # --- Criteria 3: show page displays code and expiration date ---

  test "show page displays the claim code" do
    sign_in @user
    claim = DealClaim.create!(user: @user, deal: @deal, studio: @studio)

    get "/s/#{@studio.slug}/deal_claims/#{claim.id}"

    assert_response :success
    assert_match claim.code, response.body
  end

  test "show page displays the expiration date when deal has expiry_days" do
    sign_in @user
    claim = DealClaim.create!(user: @user, deal: @deal, studio: @studio)
    expected_date = claim.expires_at.strftime("%d.%m.%Y")

    get "/s/#{@studio.slug}/deal_claims/#{claim.id}"

    assert_match expected_date, response.body
  end

  test "show page does not display an expiration date when deal has no expiry_days" do
    deal_no_expiry = Deal.create!(
      studio: @studio,
      name: "No Expiry Deal",
      deal_type: "discount",
      trigger_condition: "first_visit",
      active: true,
      expiry_days: nil
    )
    sign_in @user
    claim = DealClaim.create!(user: @user, deal: deal_no_expiry, studio: @studio)

    get "/s/#{@studio.slug}/deal_claims/#{claim.id}"

    assert_response :success
    assert_no_match "Expires at", response.body
  end

  test "user cannot view another user's claim" do
    other_user  = User.create!(email: "other@claims-ctrl.com", password: "Password123", confirmed_at: Time.current)
    other_deal  = Deal.create!(studio: @studio, name: "Other Deal", deal_type: "discount",
                               trigger_condition: "first_visit", active: true)
    other_claim = DealClaim.create!(user: other_user, deal: other_deal, studio: @studio)

    sign_in @user
    get "/s/#{@studio.slug}/deal_claims/#{other_claim.id}"
    assert_response :not_found
  end
end
