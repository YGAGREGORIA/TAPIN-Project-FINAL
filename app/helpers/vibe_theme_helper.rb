module VibeThemeHelper
  VIBE_PALETTES = {
    "Energetic"  => { primary: "#FF5200", accent: "#FF8C00", bg: "#FFF8F0", text: "#1A1A1A" },
    "Bold"       => { primary: "#E94560", accent: "#1A1A2E", bg: "#16213E", text: "#FFFFFF" },
    "Minimalist" => { primary: "#2C2C2C", accent: "#888888", bg: "#FFFFFF", text: "#2C2C2C" },
    "Welcoming"  => { primary: "#5E8B7E", accent: "#A7C4BC", bg: "#FFF5E4", text: "#333333" },
    "Premium"    => { primary: "#C9A84C", accent: "#1C1C1C", bg: "#0D0D0D", text: "#F5F5F5" },
    "Intense"    => { primary: "#CC0000", accent: "#FF3333", bg: "#1A0000", text: "#FFFFFF" },
    "Playful"    => { primary: "#FF69B4", accent: "#FFD700", bg: "#FFFACD", text: "#333333" },
    "Elite"      => { primary: "#2F4F4F", accent: "#D4AF37", bg: "#F5F5F5", text: "#1A1A1A" }
  }.freeze

  # Returns a CSS string of custom property declarations for the studio's vibe.
  # The first selected keyword is treated as the dominant vibe and drives the palette.
  # Injected as an inline <style> block in the user-facing layout at runtime — no recompile needed.
  def studio_vibe_styles(studio_brand)
    keywords = Array(studio_brand&.vibe_keywords).compact.reject(&:empty?)
    return "" if keywords.empty?

    palette = VIBE_PALETTES[keywords.first]
    return "" unless palette

    <<~CSS
      :root {
        --studio-primary: #{palette[:primary]};
        --studio-accent:  #{palette[:accent]};
        --studio-bg:      #{palette[:bg]};
        --studio-text:    #{palette[:text]};
      }
    CSS
  end

  # Returns space-separated body class names for each selected vibe keyword,
  # e.g. "vibe-energetic vibe-bold" — usable by SCSS rules for deeper overrides.
  def studio_vibe_classes(studio_brand)
    Array(studio_brand&.vibe_keywords).compact.reject(&:empty?)
                                      .map { |k| "vibe-#{k.downcase}" }
                                      .join(" ")
  end
end
