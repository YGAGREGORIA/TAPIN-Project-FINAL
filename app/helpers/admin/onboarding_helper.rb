module Admin::OnboardingHelper
  STEPS = [
    { number: 1, title: "Connect Mindbody", partial: "connect" },
    { number: 2, title: "Import Studio Information", partial: "studio" },
    { number: 3, title: "Import Teachers", partial: "teachers" },
    { number: 4, title: "Import Classes", partial: "classes" },
    { number: 5, title: "Import Members", partial: "members" },
    { number: 6, title: "Check-in Setup", partial: "checkin" },
    { number: 7, title: "Studio Branding", partial: "branding" },
    { number: 8, title: "Final Setup", partial: "complete" }
  ].freeze

  STUDIO_INFO = {
    name: "Zen Flow Yoga Studio",
    address: "Friedrichstraße 123",
    postal_city: "10117 Berlin",
    phone: "+49 30 12345678",
    email: "hello@zenflow.yoga",
    description: "Premium Yoga & Wellness Studio im Herzen von Berlin. Wir bieten eine breite Palette von Yoga-Stilen, Meditation und Wellness-Programmen für alle Levels."
  }.freeze

  def step_partial_name(step_number)
    STEPS.find { |s| s[:number] == step_number }&.dig(:partial) || "connect"
  end

  def step_css_class(step_number, current_step)
    if step_number < current_step
      "completed"
    elsif step_number == current_step
      "active"
    else
      "upcoming"
    end
  end
end
