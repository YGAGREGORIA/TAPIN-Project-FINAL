require "test_helper"

class DeviseAuthenticationTest < ActionDispatch::IntegrationTest
  def with_enabled_providers(providers)
    original_method = User.method(:enabled_omniauth_providers)
    User.singleton_class.define_method(:enabled_omniauth_providers) { providers }
    yield
  ensure
    User.singleton_class.define_method(:enabled_omniauth_providers, original_method)
  end

  test "sign up page shows studio and provider buttons" do
    with_enabled_providers(%i[google_oauth2 facebook apple]) do
      get new_user_registration_path
    end

    assert_response :success
    assert_match "Studio", response.body
    assert_match "Sign up with Google", response.body
    assert_match "Sign up with Facebook", response.body
    assert_match "Sign up with Apple", response.body
  end

  test "sign in page does not show studio field" do
    with_enabled_providers(%i[google_oauth2 facebook apple]) do
      get new_user_session_path
    end

    assert_response :success
    assert_no_match(/label[^>]*>Studio</i, response.body)
    assert_match "Continue with Google", response.body
    assert_match "Continue with Facebook", response.body
    assert_match "Continue with Apple", response.body
  end

  test "sign up stores studio through devise strong parameters" do
    assert_difference("User.count", 1) do
      post user_registration_path, params: {
        user: {
          studio: "Tapin Studio",
          email: "studio-owner@example.com",
          password: "Password123"
        }
      }
    end

    assert_equal "Tapin Studio", User.order(:id).last.studio
  end

  test "sign up normalizes the email" do
    post user_registration_path, params: {
      user: {
        studio: "Tapin Studio",
        email: "  MixedCase@Example.COM ",
        password: "Password123"
      }
    }

    assert_equal "mixedcase@example.com", User.order(:id).last.email
  end

  test "sign up rejects weak passwords" do
    assert_no_difference("User.count") do
      post user_registration_path, params: {
        user: {
          studio: "Tapin Studio",
          email: "weak-password@example.com",
          password: "password123"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "uppercase letter", response.body
  end
end
