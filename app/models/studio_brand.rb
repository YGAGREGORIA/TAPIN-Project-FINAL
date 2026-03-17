class StudioBrand < ApplicationRecord
  belongs_to :studio
  has_one_attached :logo

  VIBE_KEYWORDS = %w[Energetic Bold Minimalist Welcoming Premium Intense Playful Elite].freeze

  URL_FORMAT = /\Ahttps?:\/\/.+/i

  validates :instagram_url, format: { with: URL_FORMAT, message: "must be a valid URL starting with http(s)://" }, allow_blank: true
  validates :facebook_url,  format: { with: URL_FORMAT, message: "must be a valid URL starting with http(s)://" }, allow_blank: true
  validates :website_url,   format: { with: URL_FORMAT, message: "must be a valid URL starting with http(s)://" }, allow_blank: true
end
