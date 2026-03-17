require "net/http"
require "uri"

# Generates a white-label branding proposal for a studio.
#
# Priority hierarchy (highest → lowest):
#   1. Website URL     — scraped content, meta tags, theme-color
#   2. Instagram/Facebook URL — social brand signals
#   3. Studio philosophy — admin's own words about their brand
#   4. Vibe keywords   — last resort if no URL content is available
#
class StudioBrandingProposalService
  MAX_FETCH_CHARS = 5_000

  # Curated Google Font pairs mapped to brand personalities.
  # Claude picks from this list — no risk of invalid or obscure font names.
  FONT_PAIRS = [
    { heading: "Playfair Display",   body: "Lato",              personality: "Premium, luxury, high-end" },
    { heading: "Oswald",             body: "Open Sans",         personality: "Energetic, bold, intense, athletic" },
    { heading: "Space Grotesk",      body: "Inter",             personality: "Minimalist, modern, clean, tech" },
    { heading: "Poppins",            body: "Nunito",            personality: "Welcoming, friendly, playful, community-focused" },
    { heading: "Bebas Neue",         body: "Barlow",            personality: "Intense, strong, elite, performance" },
    { heading: "DM Sans",            body: "DM Sans",           personality: "Sleek, contemporary, neutral, versatile" },
    { heading: "Cormorant Garamond", body: "Raleway",           personality: "Elegant, refined, boutique, sophisticated" },
    { heading: "Montserrat",         body: "Source Sans Pro",   personality: "Professional, trustworthy, established" },
    { heading: "Anton",              body: "Roboto",            personality: "High-impact, gym, CrossFit, powerlifting" },
    { heading: "Raleway",            body: "Mulish",            personality: "Boutique, yoga, pilates, wellness" },
    { heading: "Nunito",             body: "Nunito",            personality: "Soft, inclusive, community-driven, accessible" },
    { heading: "Barlow Condensed",   body: "Barlow",            personality: "Performance, cycling, HIIT, functional fitness" },
    { heading: "Josefin Sans",       body: "Josefin Sans",      personality: "Geometric, minimal, Nordic, design-forward" },
    { heading: "Cinzel",             body: "EB Garamond",       personality: "Ultra-premium, spa, retreat, exclusive" },
    { heading: "Exo 2",              body: "Exo 2",             personality: "Futuristic, tech-driven, esports fitness, innovation" },
    { heading: "Libre Baskerville",  body: "Libre Franklin",    personality: "Classic, established, trusted, traditional" },
  ].freeze

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

  # Build context in strict priority order so Claude weights signals correctly.
  def build_context
    sections = []

    sections << "## Studio name\n#{@brand.studio.name}"

    # ── Priority 1: Website (richest brand signal) ──────────────────────────
    if @brand.website_url.present?
      meta, body = fetch_url_with_meta(@brand.website_url)
      content_parts = []
      content_parts << "Meta tags:\n#{meta}" if meta.present?
      content_parts << "Page content:\n#{body}"  if body.present?

      if content_parts.any?
        sections << "## Website content [PRIMARY SOURCE — weight this most heavily]\nURL: #{@brand.website_url}\n\n#{content_parts.join("\n\n")}"
      end
    end

    # ── Priority 2: Social media URLs ───────────────────────────────────────
    social_parts = []
    social_parts << "Instagram: #{@brand.instagram_url}" if @brand.instagram_url.present?
    social_parts << "Facebook: #{@brand.facebook_url}"   if @brand.facebook_url.present?
    if social_parts.any?
      sections << "## Social media [SECONDARY SOURCE]\n#{social_parts.join("\n")}\nUse the handle/username and URL structure to infer brand personality and audience."
    end

    # ── Priority 3: Philosophy ───────────────────────────────────────────────
    if @brand.philosophy.present?
      sections << "## Studio philosophy [SUPPORTING CONTEXT]\n#{@brand.philosophy}"
    end

    # ── Priority 4: Vibe keywords (last resort) ──────────────────────────────
    if @brand.vibe_keywords.present?
      keywords = Array(@brand.vibe_keywords).reject(&:empty?)
      if keywords.any?
        sections << "## Vibe keywords [LAST RESORT — only use if no URL content is available]\n#{keywords.join(', ')}"
      end
    end

    sections.join("\n\n---\n\n")
  end

  # Fetch a URL and separately extract meta tags vs body text.
  # Returns [meta_string, body_string].
  def fetch_url_with_meta(url)
    uri = URI.parse(url)
    return [nil, nil] unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: uri.scheme == "https",
                               open_timeout: 5,
                               read_timeout: 8) do |http|
      http.get(uri.request_uri, "User-Agent" => "TapIn-BrandBot/1.0")
    end

    return [nil, nil] unless response.is_a?(Net::HTTPSuccess)

    # Net::HTTP returns ASCII-8BIT — force to UTF-8 before any string operations
    html = response.body.dup.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    # Extract high-signal meta tags first
    meta_lines = []
    meta_lines << html[/<title[^>]*>(.*?)<\/title>/im, 1]&.strip
    meta_lines << html[/name=["']description["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*name=["']description["']/i, 1]
    meta_lines << html[/property=["']og:description["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*property=["']og:description["']/i, 1]
    meta_lines << html[/name=["']theme-color["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*name=["']theme-color["']/i, 1]
    meta_string = meta_lines.compact.uniq.reject(&:empty?).join("\n").presence

    # Strip scripts/styles then extract readable body text
    body_text = html
      .gsub(/<style[^>]*>.*?<\/style>/mi, "")
      .gsub(/<script[^>]*>.*?<\/script>/mi, "")
      .gsub(/<[^>]+>/, " ")
      .gsub(/\s+/, " ")
      .strip
      .first(MAX_FETCH_CHARS)

    [meta_string, body_text.presence]
  rescue StandardError => e
    Rails.logger.warn("StudioBrandingProposalService: could not fetch #{url} — #{e.message}")
    [nil, nil]
  end

  def ask_claude(context)
    llm = RubyLLM.chat(model: "claude-sonnet-4-5")
    llm.with_instructions(system_prompt)
    result = llm.ask(context)
    result.content
  end

  def system_prompt
    font_pairs_list = FONT_PAIRS.map.with_index(1) do |pair, i|
      "  #{i}. Heading: \"#{pair[:heading]}\" + Body: \"#{pair[:body]}\" — best for: #{pair[:personality]}"
    end.join("\n")

    <<~PROMPT
      You are a professional brand identity designer specialising in fitness and wellness studios.

      You will receive brand signals in STRICT PRIORITY ORDER. You must weight them accordingly:

      1. WEBSITE CONTENT — this is your primary source. Extract real colours, tone, visual identity, and language directly from the scraped content. If a theme-color meta tag is present, use it as the primary_color.
      2. SOCIAL MEDIA URLs — use the handle and URL structure to infer audience and personality.
      3. STUDIO PHILOSOPHY — use this to understand what the studio values.
      4. VIBE KEYWORDS — treat these as a last resort only. If strong website/social signals exist, ignore the keywords entirely. Only use them if no URL content was provided.

      Your job is to produce a white-label brand identity for the studio's member-facing app. The result must feel like it genuinely belongs to this specific studio, not a generic fitness brand.

      Choose a font pair from this approved list ONLY — do not use any font not on this list:
#{font_pairs_list}

      Return ONLY a valid JSON object — no markdown, no explanation. Use this exact structure:

      {
        "primary_color": "#hex",
        "secondary_color": "#hex",
        "background_color": "#hex",
        "text_color": "#hex",
        "font_heading": "exact heading font name from the approved list above",
        "font_body": "exact body font name from the approved list above",
        "tagline": "short punchy tagline for the studio, max 8 words",
        "brand_tone": "2-3 word description of the brand voice"
      }

      Constraints:
      - All hex values must be valid 6-digit hex codes
      - text_color must achieve WCAG AA contrast (4.5:1) against background_color
      - Colours must feel like they came from the studio's actual brand — not generic
      - font_heading and font_body must be copied exactly from the approved list
      - Return only JSON — nothing else
    PROMPT
  end

  def parse_response(raw)
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
