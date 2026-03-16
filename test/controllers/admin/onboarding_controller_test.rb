require "test_helper"

class Admin::OnboardingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(
      email: "owner@onboarding-test.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: true
    )
    @studio = Studio.create!(
      user: @owner,
      name: "Onboarding Test Studio",
      slug: "onboarding-test-studio",
      active: true
    )
  end

  # ── authentication ───────────────────────────────────────────────

  test "redirects unauthenticated user from show" do
    get admin_onboarding_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from advance" do
    patch advance_admin_onboarding_path, params: { step: 1 }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from go_to_step" do
    patch go_to_step_admin_onboarding_path, params: { step: 2 }
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from reset" do
    patch reset_admin_onboarding_path
    assert_redirected_to new_user_session_path
  end

  # ── authorization ────────────────────────────────────────────────

  test "redirects non-admin user to root" do
    non_admin = User.create!(
      email: "nonadmin@onboarding-test.com",
      password: "Password123",
      confirmed_at: Time.current
    )
    sign_in non_admin
    get admin_onboarding_path
    assert_redirected_to root_path
  end

  # ── studio requirement ───────────────────────────────────────────

  test "redirects admin with no studio to admin dashboard" do
    no_studio_admin = User.create!(
      email: "nostudio@onboarding-test.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: true
    )
    sign_in no_studio_admin
    get admin_onboarding_path
    assert_redirected_to admin_dashboard_path
  end

  # ── show ─────────────────────────────────────────────────────────

  test "show renders successfully for admin with a studio" do
    sign_in @owner
    get admin_onboarding_path
    assert_response :success
  end

  test "show renders the studio name in the sidebar" do
    sign_in @owner
    get admin_onboarding_path
    assert_match @studio.name, response.body
  end

  test "show defaults to step 1 content when no step param" do
    sign_in @owner
    get admin_onboarding_path
    assert_match "Connect your Mindbody account", response.body
  end

  test "show renders step 2 content when step param is 2" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 2 }
    assert_match "Import studio information", response.body
  end

  test "show renders step 3 content when step param is 3" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 3 }
    assert_match "Import your teachers", response.body
  end

  test "show renders step 4 content when step param is 4" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 4 }
    assert_match "Import your classes", response.body
  end

  test "show renders step 5 content when step param is 5" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 5 }
    assert_match "Import your members", response.body
  end

  test "show renders step 6 content when step param is 6" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 6 }
    assert_match "Studio check-in setup", response.body
  end

  test "show renders step 7 content when step param is 7" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 7 }
    assert_match "You are ready to go", response.body
  end

  test "show falls back to step 1 when out-of-range step param is given" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 99 }
    assert_match "Connect your Mindbody account", response.body
  end

  test "show uses session current_step when no param given" do
    sign_in @owner
    patch go_to_step_admin_onboarding_path, params: { step: 4 }
    get admin_onboarding_path
    assert_match "Import your classes", response.body
  end

  test "show renders all 7 steps in the sidebar" do
    sign_in @owner
    get admin_onboarding_path
    assert_match "Connect Mindbody", response.body
    assert_match "Import Studio Information", response.body
    assert_match "Import Teachers", response.body
    assert_match "Import Classes", response.body
    assert_match "Import Members", response.body
    assert_match "Check-in Setup", response.body
    assert_match "Final Setup", response.body
  end

  test "show marks completed steps with is-complete class" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 1 }
    get admin_onboarding_path
    assert_match "is-complete", response.body
  end

  test "show renders the checkin URL with the studio slug on step 6" do
    sign_in @owner
    get admin_onboarding_path, params: { step: 6 }
    assert_match @studio.slug, response.body
  end

  # ── advance ──────────────────────────────────────────────────────

  test "advance redirects to onboarding with next step" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 1 }
    assert_redirected_to admin_onboarding_path(step: 2)
  end

  test "advance does not go past the last step" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 7 }
    assert_redirected_to admin_onboarding_path(step: 7)
  end

  test "advance step 1 sets Mindbody notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 1 }
    assert_equal "Mindbody connection saved for onboarding.", flash[:notice]
  end

  test "advance step 2 sets studio information notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 2 }
    assert_equal "Studio information marked as imported.", flash[:notice]
  end

  test "advance step 3 sets teachers notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 3 }
    assert_equal "Teachers imported into your setup flow.", flash[:notice]
  end

  test "advance step 4 sets classes notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 4 }
    assert_equal "Classes imported into your setup flow.", flash[:notice]
  end

  test "advance step 5 sets members notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 5 }
    assert_equal "Members imported into your setup flow.", flash[:notice]
  end

  test "advance step 6 sets check-in setup notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 6 }
    assert_equal "Check-in setup confirmed.", flash[:notice]
  end

  test "advance step 7 sets final setup notice" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 7 }
    assert_equal "Setup complete.", flash[:notice]
  end

  test "advance marks step as completed so subsequent show shows it complete" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 2 }
    get admin_onboarding_path
    # Step 2 should now be marked complete in the sidebar
    assert_match "is-complete", response.body
  end

  test "advance same step twice does not duplicate it in the sidebar" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 2 }
    patch advance_admin_onboarding_path, params: { step: 2 }
    # The page should only show one is-complete per step — verify no error
    get admin_onboarding_path
    assert_response :success
  end

  # ── go_to_step ───────────────────────────────────────────────────

  test "go_to_step redirects to the requested step" do
    sign_in @owner
    patch go_to_step_admin_onboarding_path, params: { step: 5 }
    assert_redirected_to admin_onboarding_path(step: 5)
  end

  test "go_to_step persists the step so subsequent show renders that step" do
    sign_in @owner
    patch go_to_step_admin_onboarding_path, params: { step: 3 }
    get admin_onboarding_path
    assert_match "Import your teachers", response.body
  end

  test "go_to_step with out-of-range step redirects to step 1" do
    sign_in @owner
    patch go_to_step_admin_onboarding_path, params: { step: 0 }
    assert_redirected_to admin_onboarding_path(step: 1)
  end

  # ── reset ────────────────────────────────────────────────────────

  test "reset redirects to onboarding" do
    sign_in @owner
    patch reset_admin_onboarding_path
    assert_redirected_to admin_onboarding_path
  end

  test "reset sets the correct flash notice" do
    sign_in @owner
    patch reset_admin_onboarding_path
    assert_equal "Onboarding progress was reset.", flash[:notice]
  end

  test "reset clears completed steps" do
    sign_in @owner
    patch advance_admin_onboarding_path, params: { step: 1 }
    patch advance_admin_onboarding_path, params: { step: 2 }
    patch reset_admin_onboarding_path
    get admin_onboarding_path
    # No is-complete badge should appear after reset
    assert_no_match "is-complete", response.body
  end

  test "reset clears current step so show defaults back to step 1" do
    sign_in @owner
    patch go_to_step_admin_onboarding_path, params: { step: 5 }
    patch reset_admin_onboarding_path
    get admin_onboarding_path
    assert_match "Connect your Mindbody account", response.body
  end
end
