namespace :tapin do
  desc "Seed full demo data for a member. Usage: rails tapin:seed_demo[phone,studio_slug]"
  task :seed_demo, [:phone, :studio_slug] => :environment do |_t, args|
    phone = args[:phone] || "17612345678"
    slug  = args[:studio_slug] || "test-zen-studio"

    user = User.find_by!(phone: phone)
    studio = Studio.find_by!(slug: slug)

    puts "Seeding demo data for #{user.display_name} (#{phone}) at #{studio.name}..."

    # ── 1. Class Configs ──
    class_defs = [
      { class_name: "Vinyasa Flow",  point_value: 10, is_premium: false },
      { class_name: "Power Yoga",    point_value: 10, is_premium: true },
      { class_name: "Yin & Restore", point_value: 10, is_premium: false },
      { class_name: "Barre Burn",    point_value: 10, is_premium: false },
      { class_name: "Pilates Core",  point_value: 10, is_premium: false }
    ]

    configs = class_defs.map do |attrs|
      studio.class_configs.find_or_create_by!(class_name: attrs[:class_name]) do |cc|
        cc.point_value = attrs[:point_value]
        cc.is_premium  = attrs[:is_premium]
      end
    end
    puts "  ✓ #{configs.size} class configs"

    # ── 2. Visits (fill up to 10) ──
    existing = user.visits.where(studio: studio).count
    needed = [10 - existing, 0].max

    needed.times do |i|
      days_ago = 30 - (i * 3)
      Visit.create!(
        user: user,
        studio: studio,
        class_config: configs.sample,
        visited_at: days_ago.days.ago.change(hour: 9 + rand(0..3)),
        points_earned: 10
      )
    end
    total_visits = user.visits.where(studio: studio).count
    puts "  ✓ #{total_visits} total visits (#{needed} new + #{existing} existing)"

    # ── 3. Deals ──
    deal_defs = [
      { name: "20% Off First Booking", deal_type: "discount", discount_percent: 20,
        active: true, expiry_days: 30, trigger_condition: "first_visit" },
      { name: "Free Mat Rental", deal_type: "discount", discount_percent: nil,
        active: true, expiry_days: 14, trigger_condition: nil },
      { name: "Bring a Friend, Both Get 10% Off", deal_type: "discount", discount_percent: 10,
        active: true, expiry_days: 60, trigger_condition: "referral" }
    ]

    deals = deal_defs.map do |attrs|
      studio.deals.find_or_create_by!(name: attrs[:name]) do |d|
        d.deal_type         = attrs[:deal_type]
        d.discount_percent  = attrs[:discount_percent]
        d.active            = attrs[:active]
        d.expiry_days       = attrs[:expiry_days]
        d.trigger_condition = attrs[:trigger_condition]
      end
    end
    puts "  ✓ #{deals.size} active deals"

    # ── 4. Bookings (upcoming) ──
    booking_defs = [
      { class_name: "Vinyasa Flow",  days_from_now: 1, hour: 9 },
      { class_name: "Barre Burn",    days_from_now: 3, hour: 18 },
      { class_name: "Yin & Restore", days_from_now: 5, hour: 10 }
    ]

    bookings = booking_defs.map do |attrs|
      class_time = attrs[:days_from_now].days.from_now.change(hour: attrs[:hour])
      user.bookings.find_or_create_by!(studio: studio, class_name: attrs[:class_name], class_time: class_time) do |b|
        b.status    = true
        b.booked_at = Time.current
      end
    end
    puts "  ✓ #{bookings.size} upcoming bookings"

    # ── 5. Reward check ──
    reward = studio.rewards.find_by(reward_type: :free_class, active: true)
    if reward
      puts "  ✓ Reward exists: #{reward.name}"
    else
      puts "  ⚠ No active free_class reward found — create one in admin"
    end

    puts ""
    puts "Seeded demo data for #{studio.name}:"
    puts "  - #{configs.size} class configs (#{configs.map(&:class_name).join(', ')})"
    puts "  - #{total_visits} total visits (#{needed} new + #{existing} existing)"
    puts "  - #{deals.size} active deals"
    puts "  - #{bookings.size} upcoming bookings"
    puts "  - Reward: #{reward&.name || 'NONE — create in admin'}"
    puts "  Ready to test reward redemption!"
  end
end
