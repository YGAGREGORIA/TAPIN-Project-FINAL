module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def google_oauth2
      handle_callback("Google")
    end

    def facebook
      handle_callback("Facebook")
    end

    def apple
      handle_callback("Apple")
    end

    def failure
      redirect_to new_user_session_path, alert: "Social sign in could not be completed."
    end

    private

    def handle_callback(kind)
      @user = User.from_omniauth(request.env["omniauth.auth"])
      set_flash_message(:notice, :success, kind: kind) if is_navigational_format?
      sign_in_and_redirect @user, event: :authentication
    rescue ActiveRecord::RecordInvalid => e
      redirect_to new_user_registration_path, alert: e.record.errors.full_messages.to_sentence.presence || "#{kind} sign in failed."
    end
  end
end
