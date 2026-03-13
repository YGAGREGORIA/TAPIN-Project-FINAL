require "test_helper"

class PhoneAuthenticationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email: "owner-phone-auth@example.com",
      password: "password"
    )
    @studio = Studio.create!(
      user: @owner,
      name: "Phone Auth Studio",
      slug: "phone-auth-studio",
      active: true
    )
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 777,
      class_name: "Check In Class",
      point_value: 10,
      is_premium: false
    )
  end

  test "phone login sends a code and redirects to verification" do
    post studio_phone_login_path(studio_slug: @studio.slug), params: { phone_number: "+49 171 2345678" }

    assert_redirected_to verify_studio_phone_login_path(studio_slug: @studio.slug)
    assert_equal "491712345678", PhoneLoginCode.last.phone_number
    assert_match(/DEV_CODE: \d{6}/, flash[:notice])
  end

  test "verification creates or logs in a user and stores the visit" do
    post studio_phone_login_path(studio_slug: @studio.slug), params: { phone_number: "0171 2345678" }

    code = flash[:notice][/DEV_CODE: (\d{6})/, 1]
    post confirm_studio_phone_login_path(studio_slug: @studio.slug), params: { verification_code: code }

    assert_redirected_to dashboard_path

    user = User.find_by(phone_number: "01712345678")
    assert_not_nil user
    assert_equal 1, user.visits.where(studio: @studio).count
    assert PhoneLoginCode.last.consumed_at.present?
  end

  test "existing signed in members skip the phone form on the next tap" do
    user = User.create!(
      email: "member-returning@example.com",
      password: "password",
      phone_number: "491700000000"
    )

    post user_session_path, params: { user: { email: user.email, password: "password" } }
    get studio_landing_path(studio_slug: @studio.slug)

    assert_redirected_to dashboard_path
    assert_equal 1, user.reload.visits.where(studio: @studio).count
  end

  test "existing legacy phone users are reused instead of duplicated" do
    existing_user = User.create!(
      email: "legacy-phone@example.com",
      password: "password",
      phone: 617555111
    )

    post studio_phone_login_path(studio_slug: @studio.slug), params: { phone_number: "617555111" }
    code = flash[:notice][/DEV_CODE: (\d{6})/, 1]

    post confirm_studio_phone_login_path(studio_slug: @studio.slug), params: { verification_code: code }

    assert_redirected_to dashboard_path
    assert_equal existing_user.id, User.find_by(phone_number: "617555111").id
    assert_equal 1, User.where(email: "legacy-phone@example.com").count
  end
end
