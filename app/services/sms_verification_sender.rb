require "base64"
require "net/http"

class SmsVerificationSender
  Result = Struct.new(:success?, :message, keyword_init: true)

  def initialize(phone_number:, code:)
    @phone_number = phone_number
    @code = code
  end

  def call
    return development_result unless credentials_configured?

    response = Net::HTTP.post(
      URI("https://api.twilio.com/2010-04-01/Accounts/#{ENV.fetch("TWILIO_ACCOUNT_SID")}/Messages.json"),
      URI.encode_www_form(
        To: formatted_phone_number,
        From: ENV.fetch("TWILIO_FROM_NUMBER"),
        Body: "Your TAPIN confirmation code is #{@code}"
      ),
      authorization_header
    )

    if response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)
      Result.new(success?: true, message: "Verification code sent.")
    else
      Rails.logger.error("Twilio SMS failed: #{response.code} #{response.body}")
      Result.new(success?: false, message: "The confirmation code could not be sent.")
    end
  rescue StandardError => error
    Rails.logger.error("Twilio SMS exception: #{error.class} #{error.message}")
    Result.new(success?: false, message: "The confirmation code could not be sent.")
  end

  private

  def credentials_configured?
    ENV["TWILIO_ACCOUNT_SID"].present? &&
      ENV["TWILIO_AUTH_TOKEN"].present? &&
      ENV["TWILIO_FROM_NUMBER"].present?
  end

  def development_result
    Rails.logger.info("SMS fallback for #{@phone_number}: verification code #{@code}")
    Result.new(success?: true, message: "DEV_CODE: #{@code}")
  end

  def formatted_phone_number
    return @phone_number if @phone_number.start_with?("+")

    "+#{@phone_number}"
  end

  def authorization_header
    token = Base64.strict_encode64(
      "#{ENV.fetch("TWILIO_ACCOUNT_SID")}:#{ENV.fetch("TWILIO_AUTH_TOKEN")}"
    )

    {
      "Authorization" => "Basic #{token}",
      "Content-Type" => "application/x-www-form-urlencoded"
    }
  end
end
