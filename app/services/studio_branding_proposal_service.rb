require "net/http"
require "uri"

# Generates a white-label branding proposal for a studio by:
# 1. Fetching content from the studio's website and/or Instagram URL
# 2. Combining that with the admin's philosophy text and vibe keywords
# 3. Asking Claude to produce a structured brand identity (colors, fonts, tagline, tone)
#
# Returns a hash matching StudioBrand column names, ready to be saved.
#
# Usage:
#   result = StudioBrandingProposalService.call(studio_brand)
#   # => { primary_color: "#2C3E50", font_heading: "Playfair Display", ... }
class StudioBrandingProposalService
  MAX_FETCH_CHARS = 2_000

  def self.call(studio_brand)
    new(studio_brand).call
  end

  def initialize(studio_brand)
    @brand = studio_brand
  end

  def call
    context = build_context
    raw = ask_claude(context)
    parse_response(raw)
  rescue StandardError => e
    Rails.logger.error("StudioBrandingProposalService error: #{e.class} — #{e.message}")
    nil
  end

  private

  def build_context
    sections = []

    sections << "Studio name: #{@brand.studio.name}"

    if @brand.philosophy.present?
      sections << "Studio philosophy: #{@brand.philosophy}"
    end

    if @brand.vibe_keywords.present?
      sections << "Vibe keywords chosen by the studio owner: #{Array(@brand.vibe_keywords).join(', ')}"
    end

    if @brand.website_url.present?
      content = fetch_url(@brand.website_url)
      sections << "Website content (#{@brand.website_url}):\n#{content}" if content.present?
    end

    if @brand.instagram_url.present?
      sections << "Instagram handle/URL: #{@brand.instagram_url}"
    end

    if @brand.facebook_url.present?
      sections << "Facebook URL: #{@brand.facebook_url}"
    end

    sections.join("\n\n")
  end

  def fetch_url(url)
    uri = URI.parse(url)
    return nil unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 8) do |http|
      http.get(uri.request_uri, "User-Agent" => "TapIn-BrandBot/1.0")
    end

    return nil unless response.is_a?(Net::HTTPSuccess)

    # Strip HTML tags and condense whitespace, keep first MAX_FETCH_CHARS
    text = response.body
                   .gsub(/<style[^>]*>.*?<\/style>/mi, "")
                   .gsub(/<script[^>]*>.*?<\/script>/mi, "")
                   .gsub(/<[^>]+>/, " ")
                   .gsub(/\s+/, " ")
                   .strip
                   .first(MAX_FETCH_CHARS)
    text.presence
  rescue StandardError => e
    Rails.logger.warn("StudioBrandingProposalService: could not fetch #{url} — #{e.message}")
    nil
  end

  def ask_claude(context)
    llm = RubyLLM.chat(model: "claude-sonnet-4-5")
    llm.with_instructions(system_prompt)
    result = llm.ask(context)
    result.content
  end

  def system_prompt
    <<~PROMPT
      You are a professional brand identity designer specialising in fitness and wellness studios.

      You will receive information about a sports studio — its name, philosophy, vibe keywords, and optionally scraped content from their website and social media.

      Your job is to produce a cohesive white-label brand identity for their member-facing app.

      Respond with ONLY a valid JSON object — no markdown, no explanation, just JSON. Use this exact structure:

      {
        "primary_color": "#hex — the dominant brand colour, used for navbars, hero sections, buttons",
        "secondary_color": "#hex — a complementary accent colour for highlights and CTAs",
        "background_color": "#hex — the page background (usually light or neutral)",
        "text_color": "#hex — main body text colour (must have strong contrast with background)",
        "font_heading": "Google Font name for headings — choose something that fits the brand personality",
        "font_body": "Google Font name for body text — must be highly readable",
        "tagline": "A short punchy tagline for the studio (max 8 words)",
        "brand_tone": "2-3 word description of the brand voice, e.g. energetic and bold"
      }

      Rules:
      - All hex values must be valid 6-digit hex codes (e.g. #2C3E50)
      - text_color must achieve WCAG AA contrast (4.5:1) against background_color
      - Choose Google Fonts that are real and well-known (Inter, Space Grotesk, Playfair Display, Montserrat, etc.)
      - Colours should feel cohesive, not random — build a palette from the brand signals provided
      - If the studio content suggests a premium/dark aesthetic, lean into that
      - If it's energetic/bold, use vivid saturated colours
      - Return only JSON — nothing else
    PROMPT
  end

  def parse_response(raw)
    # Strip any accidental markdown fences Claude might add
    json_str = raw.to_s.gsub(/```json\n?/, "").gsub(/```/, "").strip
    data = JSON.parse(json_str)

    {
      primary_color:    data["primary_color"],
      secondary_color:  data["secondary_color"],
      background_color: data["background_color"],
      text_color:       data["text_color"],
      font_heading:     data["font_heading"],
      font_body:        data["font_body"],
      tagline:          data["tagline"],
      brand_tone:       data["brand_tone"]
    }.compact
  rescue JSON::ParserError => e
    Rails.logger.error("StudioBrandingProposalService: JSON parse failed — #{e.message}\nRaw: #{raw}")
    nil
  end
end
