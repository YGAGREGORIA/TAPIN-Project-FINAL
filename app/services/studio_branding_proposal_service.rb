require "net/http"
require "uri"

# Generates 3 white-label branding proposals for a studio.
#
# Priority hierarchy (highest → lowest):
#   1. Website URL     — scraped content, meta tags, theme-color, extracted hex colours
#   2. Instagram/Facebook URL — social brand signals
#   3. Studio philosophy — admin's own words about their brand
#   4. Vibe keywords   — last resort if no URL content is available
#
# Returns an array of 3 proposal hashes, each matching StudioBrand column names.
#
class StudioBrandingProposalService
  MAX_FETCH_CHARS = 5_000
  MAX_EXTRACTED_COLORS = 20

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

  def build_context
    sections = []

    sections << "## Studio name\n#{@brand.studio.name}"

    # ── Priority 1: Website (richest brand signal) ──────────────────────────
    if @brand.website_url.present?
      meta, body, extracted_colors = fetch_url_with_meta(@brand.website_url)
      content_parts = []
      content_parts << "Meta tags:\n#{meta}"                                         if meta.present?
      content_parts << "Brand colours extracted from CSS stylesheets + HTML (USE THESE — they are the real palette):\n#{extracted_colors}"      if extracted_colors.present?
      content_parts << "Page content:\n#{body}"                                      if body.present?

      # Always include the URL itself even if scrape was sparse — Claude can use its own knowledge of the brand
      header = "## Website [PRIMARY SOURCE — weight this most heavily]\nURL: #{@brand.website_url}"
      header += "\nNOTE: This site may be JS-rendered. Scraped content may be incomplete — use the URL and your knowledge of this brand to infer the real colour palette." if content_parts.empty?
      sections << [header, *content_parts].join("\n\n")
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

  GENERIC_COLORS = %w[
    #000000 #ffffff #ff0000 #cccccc #999999 #666666 #333333 #111111
    #f5f5f5 #f0f0f0 #eeeeee #e5e5e5 #dddddd #d9d9d9 #c0c0c0 #aaaaaa
    #888888 #777777 #555555 #444444 #222222 #1a1a1a #0a0a0a #fafafa
    #f9f9f9 #f8f8f8 #fcfcfc #fbfbfb #2c2c2c #3c3c3c #4c4c4c #5c5c5c
    #0d6efd #6610f2 #6f42c1 #d63384 #dc3545 #fd7e14 #ffc107 #198754
    #20c997 #0dcaf0 #212529 #6c757d #343a40 #495057 #adb5bd #ced4da
    #dee2e6 #e9ecef #f8f9fa #007bff #28a745 #17a2b8 #ffc107 #dc3545
    #6c757d #343a40 #1a73e8 #4285f4 #34a853 #fbbc05 #ea4335
    #116dff #2f5dff #e03939 #ff4040 #eaefff
  ].to_set.freeze

  # Fetch a URL and return [meta_string, body_string, extracted_colors_string].
  def fetch_url_with_meta(url)
    uri = URI.parse(url)
    return [nil, nil, nil] unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)

    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: uri.scheme == "https",
                               open_timeout: 5,
                               read_timeout: 8) do |http|
      http.get(uri.request_uri, "User-Agent" => "TapIn-BrandBot/1.0")
    end

    return [nil, nil, nil] unless response.is_a?(Net::HTTPSuccess)

    # Force UTF-8 — Net::HTTP returns ASCII-8BIT
    html = response.body.dup.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    # ── Extract meta tags ──────────────────────────────────────────────────
    meta_lines = []
    meta_lines << html[/<title[^>]*>(.*?)<\/title>/im, 1]&.strip
    meta_lines << html[/name=["']description["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*name=["']description["']/i, 1]
    meta_lines << html[/property=["']og:description["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*property=["']og:description["']/i, 1]
    meta_lines << html[/name=["']theme-color["'][^>]*content=["']([^"']+)/i, 1]
    meta_lines << html[/content=["']([^"']+)["'][^>]*name=["']theme-color["']/i, 1]
    meta_string = meta_lines.compact.uniq.reject(&:empty?).join("\n").presence

    # ── Fetch linked CSS files and extract colors from them ────────────────
    # CSS files contain the real brand palette (custom properties, class colors)
    # even on JS-rendered sites where the HTML shell is empty.
    css_colors = extract_colors_from_stylesheets(html, uri)

    # ── Extract hex colours from raw HTML as fallback ──────────────────────
    html_colors = extract_hex_colors(html)

    # Inline <style> blocks often contain CMS brand CSS variables — check those too
    inline_css = html.scan(/<style[^>]*>(.*?)<\/style>/mi).flatten.join("\n")
    inline_colors = inline_css.present? ? extract_hex_colors(inline_css) : []

    # Priority: CSS file colors > inline style colors > raw HTML colors
    all_colors = (css_colors + inline_colors + html_colors).uniq.first(MAX_EXTRACTED_COLORS)
    colors_string = all_colors.any? ? all_colors.join(", ") : nil

    # ── Extract readable body text ─────────────────────────────────────────
    body_text = html
      .gsub(/<style[^>]*>.*?<\/style>/mi, "")
      .gsub(/<script[^>]*>.*?<\/script>/mi, "")
      .gsub(/<[^>]+>/, " ")
      .gsub(/\s+/, " ")
      .strip
      .first(MAX_FETCH_CHARS)

    [meta_string, body_text.presence, colors_string]
  rescue StandardError => e
    Rails.logger.warn("StudioBrandingProposalService: could not fetch #{url} — #{e.message}")
    [nil, nil, nil]
  end

  # Finds up to 3 linked stylesheets in the HTML, fetches them, and extracts
  # distinctive colors. CSS files reliably contain brand color definitions
  # even on JS-rendered sites where the HTML shell is empty.
  def extract_colors_from_stylesheets(html, base_uri)
    # Match <link> tags regardless of attribute order (href before or after rel)
    css_hrefs = []
    html.scan(/<link([^>]+)>/i).each do |attrs|
      attr_str = attrs.first
      next unless attr_str =~ /rel=["']stylesheet["']/i
      href_match = attr_str.match(/href=["']([^"']+)["']/i)
      css_hrefs << href_match[1] if href_match
    end

    # Only keep stylesheets from the same domain — brand CSS is always self-hosted.
    # CDN URLs (jsdelivr, unpkg, cloudflare, etc.) contain Bootstrap/Tailwind/framework
    # colors that would pollute the brand palette.
    cdn_domains = %w[jsdelivr unpkg cloudflare cdnjs bootstrapcdn googleapis fontawesome
                     stackpath ajax.aspnetcdn maxcdn]
    css_hrefs = css_hrefs
      .reject { |href| cdn_domains.any? { |cdn| href.include?(cdn) } }
      .reject { |href| href.start_with?("http") && !href.include?(base_uri.host) }
      .first(4)

    Rails.logger.debug("StudioBrandingProposalService: found #{css_hrefs.size} stylesheets to fetch")

    colors = []
    css_hrefs.each do |href|
      css_url = if href.start_with?("http")
                  href
                elsif href.start_with?("//")
                  "#{base_uri.scheme}:#{href}"
                elsif href.start_with?("/")
                  "#{base_uri.scheme}://#{base_uri.host}#{href}"
                else
                  "#{base_uri.scheme}://#{base_uri.host}/#{href}"
                end

      css_content = fetch_text(css_url)
      next unless css_content

      Rails.logger.debug("StudioBrandingProposalService: fetched CSS #{css_url} (#{css_content.length} chars)")

      # CSS custom properties with color-related names — these ARE the brand palette
      css_content.scan(/--[\w-]*(?:color|primary|accent|brand|main|theme|highlight|dark|light)[\w-]*\s*:\s*(#[0-9a-fA-F]{3,6})/i)
                 .flatten.each { |c| colors << normalise_hex(c) }

      # CSS custom properties with rgb() values
      css_content.scan(/--[\w-]*(?:color|primary|accent|brand|main|theme)[\w-]*\s*:\s*rgb\((\d+),\s*(\d+),\s*(\d+)\)/i)
                 .each { |r, g, b| colors << rgb_to_hex(r.to_i, g.to_i, b.to_i) }

      # All hex colors in the CSS as supplement
      colors.concat(extract_hex_colors(css_content))
    end

    result = colors.compact.uniq.reject { |c| GENERIC_COLORS.include?(c) }
    Rails.logger.debug("StudioBrandingProposalService: extracted CSS colors: #{result.join(', ')}")
    result
  rescue StandardError => e
    Rails.logger.warn("StudioBrandingProposalService: CSS extraction failed — #{e.message}")
    []
  end

  def rgb_to_hex(r, g, b)
    "##{r.to_s(16).rjust(2, '0')}#{g.to_s(16).rjust(2, '0')}#{b.to_s(16).rjust(2, '0')}"
  end

  def fetch_text(url)
    uri = URI.parse(url)
    response = Net::HTTP.start(uri.host, uri.port,
                               use_ssl: uri.scheme == "https",
                               open_timeout: 4,
                               read_timeout: 6) do |http|
      http.get(uri.request_uri, "User-Agent" => "TapIn-BrandBot/1.0")
    end
    return nil unless response.is_a?(Net::HTTPSuccess)
    response.body.dup.force_encoding("UTF-8").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
  rescue StandardError
    nil
  end

  def extract_hex_colors(text)
    text.scan(/#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b/)
        .map { |c| normalise_hex(c) }
        .uniq
        .reject { |c| GENERIC_COLORS.include?(c) }
  end

  def normalise_hex(color)
    c = color.downcase
    c.length == 4 ? "##{c[1]*2}#{c[2]*2}#{c[3]*2}" : c
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

      You will receive brand signals in STRICT PRIORITY ORDER. Weight them accordingly:

      1. WEBSITE URL & CONTENT — primary source.
         - "Hex colours found in page source" were extracted from the raw HTML + linked CSS stylesheets. These ARE the real brand colors — use them directly as your palette base. Do NOT invent new colors if a color list is provided.
         - CSS custom property colors (extracted from stylesheets) are the most reliable — treat them as the definitive brand palette.
         - If the color list looks generic (only grays and blacks), fall back to your own knowledge of the brand from the URL.
         - If a theme-color meta tag is present, use it as the primary_color.
         - Always cross-reference the URL with your knowledge of the brand if you recognise it.
         - Use page text content (copy, headings, descriptions) to infer personality and aesthetic.
      2. SOCIAL MEDIA URLs — use handle and URL structure to infer audience and personality.
      3. STUDIO PHILOSOPHY — use to understand values and voice.
      4. VIBE KEYWORDS — last resort only. Ignore if strong URL signals exist.

      Your job is to produce THREE distinct white-label brand proposals for the studio's member-facing app. Each proposal should feel like a legitimate interpretation of the actual brand — not generic. Give them names (e.g. "Light & Clean", "Bold & Dark", "Warm & Premium").

      Choose font pairs from this approved list ONLY:
#{font_pairs_list}

      Return ONLY a valid JSON array of exactly 3 objects — no markdown, no explanation:

      [
        {
          "name": "proposal name (2-3 words)",
          "primary_color": "#hex",
          "secondary_color": "#hex",
          "background_color": "#hex",
          "text_color": "#hex",
          "font_heading": "exact heading font name from approved list",
          "font_body": "exact body font name from approved list",
          "tagline": "short punchy tagline, max 8 words",
          "brand_tone": "2-3 word brand voice description"
        },
        { ... },
        { ... }
      ]

      Constraints:
      - All hex values must be valid 6-digit hex codes
      - text_color must achieve WCAG AA contrast (4.5:1) against background_color
      - The 3 proposals must be meaningfully different from each other — vary the palette (e.g. one light, one dark, one bold/colourful)
      - Colours must feel like they came from the studio's actual brand, not a generic fitness template
      - font_heading and font_body must be copied exactly from the approved list
      - Return only the JSON array — nothing else
    PROMPT
  end

  def parse_response(raw)
    json_str = raw.to_s.gsub(/```json\n?/, "").gsub(/```/, "").strip
    data = JSON.parse(json_str)

    raise "Expected array of proposals" unless data.is_a?(Array)

    data.map do |proposal|
      {
        name:             proposal["name"],
        primary_color:    proposal["primary_color"],
        secondary_color:  proposal["secondary_color"],
        background_color: proposal["background_color"],
        text_color:       proposal["text_color"],
        font_heading:     proposal["font_heading"],
        font_body:        proposal["font_body"],
        tagline:          proposal["tagline"],
        brand_tone:       proposal["brand_tone"]
      }.compact
    end
  rescue JSON::ParserError, RuntimeError => e
    Rails.logger.error("StudioBrandingProposalService: parse failed — #{e.message}\nRaw: #{raw}")
    nil
  end
end
