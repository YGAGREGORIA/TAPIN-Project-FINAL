# Demo data seeder — fills all tables with realistic data for both studios
# Run with: bin/rails runner db/seed_demo_data.rb

puts "=== Seeding demo data ==="

# ── Studios ──────────────────────────────────────────────────────────────────
movement_lab = Studio.find_by!(slug: "the-movement-lab")
flex_appeal = Studio.find_by!(slug: "flex-appeal")

# ── Mindbody integration settings ────────────────────────────────────────────
movement_lab.update!(mindbody_site_id: "123456", mindbody_api_key: "demo-api-key-ml-2026")
flex_appeal.update!(mindbody_site_id: "789012", mindbody_api_key: "demo-api-key-fa-2026")
puts "Mindbody settings updated"

# ── Studio brands (fill all fields) ─────────────────────────────────────────
movement_lab.studio_brand.update!(
  philosophy: "We believe movement is medicine. Our studio blends yoga, pilates, and functional training to help you find balance in body and mind.",
  website_url: "https://themovementlab.com",
  instagram_url: "https://instagram.com/themovementlab",
  facebook_url: "https://facebook.com/themovementlab",
  vibe_keywords: ["mindful", "balanced", "welcoming", "holistic", "community"]
)

flex_appeal.studio_brand.update!(
  philosophy: "We build strength that radiates confidence. High-energy classes designed to push your limits and leave you feeling unstoppable.",
  website_url: "https://flexappeal.fit",
  instagram_url: "https://instagram.com/flexappeal",
  facebook_url: "https://facebook.com/flexappealfit",
  vibe_keywords: ["bold", "energetic", "empowering", "intense", "confident"]
)
puts "Studio brands filled"

# ── Class configs ────────────────────────────────────────────────────────────
ml_classes = {
  "Morning Yoga" => { point_value: 10, is_premium: false, mindbody_class_id: "ML-101" },
  "Power Pilates" => { point_value: 12, is_premium: false, mindbody_class_id: "ML-102" },
  "Breathwork & Stretch" => { point_value: 8, is_premium: false, mindbody_class_id: "ML-103" },
  "Reformer Pilates" => { point_value: 15, is_premium: true, mindbody_class_id: "ML-104" },
  "Sunset Flow" => { point_value: 10, is_premium: false, mindbody_class_id: "ML-105" },
}

fa_classes = {
  "Power Yoga" => { point_value: 10, is_premium: false, mindbody_class_id: "FA-201" },
  "HIIT Burn" => { point_value: 15, is_premium: false, mindbody_class_id: "FA-202" },
  "Stretch & Recover" => { point_value: 8, is_premium: false, mindbody_class_id: "FA-203" },
  "Boxing Bootcamp" => { point_value: 18, is_premium: true, mindbody_class_id: "FA-204" },
  "Core Crusher" => { point_value: 12, is_premium: false, mindbody_class_id: "FA-205" },
}

[
  [movement_lab, ml_classes],
  [flex_appeal, fa_classes]
].each do |studio, classes|
  classes.each do |name, attrs|
    ClassConfig.find_or_create_by!(studio: studio, class_name: name) do |c|
      c.assign_attributes(attrs)
    end
  end
end
puts "Class configs seeded"

# ── Studio classes (scheduled sessions) ──────────────────────────────────────
[movement_lab, flex_appeal].each do |studio|
  studio.class_configs.each do |config|
    # Create classes for the next 7 days
    7.times do |day_offset|
      scheduled = (Date.today + day_offset).to_time + [7, 9, 12, 17, 19].sample.hours
      StudioClass.find_or_create_by!(
        studio: studio,
        class_config: config,
        scheduled_at: scheduled,
        name: config.class_name
      ) do |sc|
        sc.teacher_name = ["Sarah K.", "Mike T.", "Lena R.", "Chris P.", "Anna M."].sample
        sc.duration_minutes = [45, 50, 60, 75].sample
        sc.capacity = [12, 15, 20, 25].sample
        sc.spots_taken = rand(0..10)
        sc.class_type = config.is_premium ? "premium" : "regular"
        sc.description = "#{config.class_name} with #{sc.teacher_name}. #{sc.duration_minutes} minutes of focused movement."
      end
    end
  end
end
puts "Studio classes scheduled"

# ── Member users ─────────────────────────────────────────────────────────────
members = [
  { phone: "15257664554", first_name: "TestMember", last_name: "" },
  { phone: "17612345001", first_name: "Emma", last_name: "Schmidt", instagram: "@emma.moves" },
  { phone: "17612345002", first_name: "Liam", last_name: "Mueller", facebook: "liam.mueller.fit" },
  { phone: "17612345003", first_name: "Sofia", last_name: "Weber", instagram: "@sofiaflow" },
  { phone: "17612345004", first_name: "Noah", last_name: "Fischer", linkedin: "noahfischer" },
  { phone: "17612345005", first_name: "Mia", last_name: "Becker", instagram: "@mia.stretch" },
  { phone: "17612345006", first_name: "Lucas", last_name: "Wagner" },
  { phone: "17612345007", first_name: "Hannah", last_name: "Richter", instagram: "@hannahfit" },
  { phone: "17612345008", first_name: "Felix", last_name: "Koch" },
  { phone: "17612345009", first_name: "Lea", last_name: "Braun", facebook: "lea.braun.yoga" },
  { phone: "17612345010", first_name: "Jonas", last_name: "Hoffmann" },
  { phone: "17612345011", first_name: "Clara", last_name: "Schulz", instagram: "@claracore" },
]

member_users = members.map do |attrs|
  user = User.find_or_initialize_by(phone: attrs[:phone])
  if user.new_record?
    user.assign_attributes(attrs.except(:instagram, :facebook, :linkedin))
    user.email = "phone_#{attrs[:phone]}@tapin.local"
    user.password = SecureRandom.hex(16)
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save!
  end
  user.update(attrs.slice(:instagram, :facebook, :linkedin).compact)
  user
end
puts "#{member_users.size} members seeded"

# ── Visits (spread over last 30 days) ────────────────────────────────────────
member_users.each do |user|
  [movement_lab, flex_appeal].each do |studio|
    visit_count = rand(1..8)
    visit_count.times do |i|
      days_ago = rand(1..30)
      config = studio.class_configs.sample
      Visit.find_or_create_by!(
        user: user,
        studio: studio,
        visited_at: days_ago.days.ago.change(hour: [7,9,12,17,19].sample)
      ) do |v|
        v.class_config = config
        v.points_earned = config.point_value
      end
    rescue ActiveRecord::RecordInvalid
      # dedup validation — skip
    end
  end
  user.recalculate_points! if user.respond_to?(:recalculate_points!)
end
puts "Visits seeded"

# ── Bookings (upcoming) ─────────────────────────────────────────────────────
member_users.first(8).each do |user|
  [movement_lab, flex_appeal].sample(rand(1..2)).each do |studio|
    rand(1..3).times do
      sc = studio.studio_classes.where("scheduled_at > ?", Time.current).sample
      next unless sc
      Booking.find_or_create_by!(user: user, studio_class: sc) do |b|
        b.studio = studio
        b.class_name = sc.name
        b.class_time = sc.scheduled_at
        b.booked_at = Time.current - rand(1..48).hours
        b.status = "confirmed"
      end
    rescue ActiveRecord::RecordInvalid
      # skip dupes
    end
  end
end
puts "Bookings seeded"

# ── Stamp cards ──────────────────────────────────────────────────────────────
member_users.first(8).each do |user|
  [movement_lab, flex_appeal].each do |studio|
    reward = studio.rewards.active.sample
    next unless reward
    card = StampCard.find_or_create_by!(user: user, reward: reward, studio: studio) do |c|
      c.started_at = rand(1..20).days.ago
      c.stamps_collected = rand(0..[(reward.visits_required - 1), 3].min)
      c.status = "active"
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Stamp cards seeded"

# ── Deal claims ──────────────────────────────────────────────────────────────
member_users.first(6).each do |user|
  [movement_lab, flex_appeal].each do |studio|
    deal = studio.deals.active.where(trigger_condition: :first_visit).first
    next unless deal
    DealClaim.find_or_create_by!(user: user, deal: deal, studio: studio) do |dc|
      dc.claimed_at = rand(1..15).days.ago
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Deal claims seeded"

# ── Reward redemptions ───────────────────────────────────────────────────────
member_users.first(4).each do |user|
  [movement_lab, flex_appeal].sample(1).each do |studio|
    reward = studio.rewards.active.sample
    next unless reward
    RewardRedemption.find_or_create_by!(user: user, reward: reward, studio: studio) do |rr|
      rr.code = "RWD-#{SecureRandom.alphanumeric(8).upcase}"
      rr.redeemed_at = rand(1..10).days.ago
      rr.point_spent = reward.points_cost
      rr.status = "redeemed"
      rr.expiry_days = 30
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Reward redemptions seeded"

# ── Notification templates ───────────────────────────────────────────────────
[movement_lab, flex_appeal].each do |studio|
  [
    { event_type: "reward_unlocked", title_template: "Reward unlocked!", body_template: "You've earned a {{reward_name}}! Tap to redeem." },
    { event_type: "deal_available", title_template: "New deal!", body_template: "{{deal_name}} is now available. Claim it before it expires!" },
    { event_type: "booking_reminder", title_template: "Class tomorrow!", body_template: "Don't forget your {{class_name}} at {{class_time}} tomorrow." },
    { event_type: "inactive_user", title_template: "We miss you!", body_template: "It's been a while since your last visit. Come back and keep earning stamps!" },
    { event_type: "deal_expiry", title_template: "Deal expiring soon!", body_template: "Your {{deal_name}} deal expires in 2 days. Use it before it's gone!" },
  ].each do |attrs|
    NotificationTemplate.find_or_create_by!(studio: studio, event_type: attrs[:event_type]) do |nt|
      nt.title_template = attrs[:title_template]
      nt.body_template = attrs[:body_template]
      nt.enabled = true
    end
  end
end
puts "Notification templates seeded"

# ── Broadcasts ───────────────────────────────────────────────────────────────
[movement_lab, flex_appeal].each do |studio|
  [
    { subject: "New class schedule is live!", body: "We've updated our class times for the spring season. Check the app for the latest schedule and book your spot early!", channel: "push", audience_filter: "all" },
    { subject: "Double stamps this weekend!", body: "This Saturday and Sunday, every check-in earns you 2 stamps instead of 1. Don't miss out!", channel: "push", audience_filter: "active" },
    { subject: "Welcome to #{studio.name}!", body: "Thanks for joining us. Start earning stamps toward free classes and exclusive deals from day one.", channel: "push", audience_filter: "new_members" },
  ].each_with_index do |attrs, i|
    Broadcast.find_or_create_by!(studio: studio, subject: attrs[:subject]) do |b|
      b.body = attrs[:body]
      b.channel = attrs[:channel]
      b.audience_filter = attrs[:audience_filter]
      b.sent_at = (i + 1).weeks.ago
      b.scheduled_at = (i + 1).weeks.ago - 1.hour
      b.total_sent = rand(20..80)
      b.total_delivered = rand(15..70)
      b.total_failed = rand(0..3)
    end
  end
end
puts "Broadcasts seeded"

# ── Referrals ────────────────────────────────────────────────────────────────
referrer = member_users[1] # Emma
referred = member_users[6] # Lucas
Referral.find_or_create_by!(referrer: referrer, referred: referred) do |r|
  r.referral_code = "EMMA-#{SecureRandom.alphanumeric(4).upcase}"
  r.status = "completed"
  r.completed_at = 5.days.ago
end

referrer2 = member_users[3] # Sofia
referred2 = member_users[8] # Felix
Referral.find_or_create_by!(referrer: referrer2, referred: referred2) do |r|
  r.referral_code = "SOFIA-#{SecureRandom.alphanumeric(4).upcase}"
  r.status = "pending"
end
puts "Referrals seeded"

# ── Chats & messages ─────────────────────────────────────────────────────────
member_users.first(5).each do |user|
  studio = [movement_lab, flex_appeal].sample
  chat = Chat.find_or_create_by!(user: user, studio: studio) do |c|
    c.title = "Chat with #{studio.name}"
    c.status = "active"
  end

  messages = [
    { role: "user", content: "What classes do you have on weekends?", sentiment: "neutral", tag: "inquiry" },
    { role: "assistant", content: "We have Morning Yoga at 9am, Power Pilates at 11am, and Sunset Flow at 5pm on both Saturday and Sunday. Would you like to book one?", sentiment: "helpful", tag: "schedule" },
    { role: "user", content: "Can I bring a friend to try a class?", sentiment: "positive", tag: "inquiry" },
    { role: "assistant", content: "Absolutely! We have a Guest Pass reward — once you earn 5 stamps, you get a free guest pass. You can also check our deals page for a referral discount!", sentiment: "positive", tag: "rewards" },
  ]

  messages.each do |msg|
    Message.find_or_create_by!(chat: chat, content: msg[:content]) do |m|
      m.role = msg[:role]
      m.sentiment = msg[:sentiment]
      m.tag = msg[:tag]
      m.summary = msg[:content].truncate(50)
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Chats & messages seeded"

# ── Notifications ────────────────────────────────────────────────────────────
member_users.first(6).each do |user|
  studio = [movement_lab, flex_appeal].sample
  [
    { title: "Welcome back!", body: "Thanks for checking in. You earned 10 points!", notification_type: "visit", path: "/dashboard" },
    { title: "New deal available!", body: "First Class Free is waiting for you.", notification_type: "deal", path: "/s/#{studio.slug}/deals" },
    { title: "Almost there!", body: "2 more visits to earn your Free Class reward.", notification_type: "reward", path: "/s/#{studio.slug}/rewards" },
  ].each do |attrs|
    Notification.create!(
      user: user,
      studio: studio,
      title: attrs[:title],
      body: attrs[:body],
      notification_type: attrs[:notification_type],
      path: attrs[:path],
      sent_at: rand(1..14).days.ago,
      read_at: [nil, rand(1..7).days.ago].sample
    )
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Notifications seeded"

# ── Mindbody clients & links (only models that exist) ────────────────────────
# Note: mb_ tables (mb_staff, mb_classes, etc.) don't have Rails models,
# they're populated by the Mindbody sync job. Skipping those.
[
  { studio: movement_lab, site_id: "123456" },
  { studio: flex_appeal, site_id: "789012" },
].each do |ctx|
  site_id = ctx[:site_id]
  studio = ctx[:studio]

  # MindbodyClients (linking table — only model that exists for mb_ data)
  member_users.first(6).each_with_index do |user, i|
    MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "CLIENT-#{site_id}-#{i+1}") do |mc|
      mc.first_name = user.first_name
      mc.last_name = user.last_name
      mc.email = "#{user.first_name.downcase}@example.com"
      mc.phone = user.phone
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end

member_users.first(6).each_with_index do |user, i|
  MindbodyLink.find_or_create_by!(user: user) do |ml|
    ml.mindbody_client_id = "CLIENT-123456-#{i+1}"
    ml.status = "linked"
    ml.linked_at = rand(10..60).days.ago
    ml.match_data = { confidence: rand(85..99), matched_by: "phone" }.to_json
  end
rescue ActiveRecord::RecordInvalid
  # skip
end
puts "Mindbody clients & links seeded"

# ── Summary ──────────────────────────────────────────────────────────────────
puts "\n=== Demo data complete ==="
puts "Studios: #{Studio.count}"
puts "Members: #{User.where(admin: false).count}"
puts "Visits: #{Visit.count}"
puts "Bookings: #{Booking.count}"
puts "Stamp cards: #{StampCard.count}"
puts "Deal claims: #{DealClaim.count}"
puts "Reward redemptions: #{RewardRedemption.count}"
puts "Referrals: #{Referral.count}"
puts "Chats: #{Chat.count}"
puts "Messages: #{Message.count}"
puts "Notifications: #{Notification.count}"
puts "Broadcasts: #{Broadcast.count}"
puts "Notification templates: #{NotificationTemplate.count}"
puts "Mindbody clients: #{MindbodyClient.count}"
puts "Mindbody links: #{MindbodyLink.count}"

__END__
# (legacy code removed — mb_ raw tables below have no Rails models)
if false # disabled
  [
    { first_name: "Sarah", last_name: "Kim", email: "sarah@#{studio.slug}.com", bio: "Certified yoga and pilates instructor with 8 years of experience.", phone: "17699990001" },
    { first_name: "Mike", last_name: "Torres", email: "mike@#{studio.slug}.com", bio: "Former athlete turned fitness coach. Specializes in HIIT and strength training.", phone: "17699990002" },
    { first_name: "Lena", last_name: "Richter", email: "lena@#{studio.slug}.com", bio: "Breathwork and mindfulness practitioner. Believes in the healing power of movement.", phone: "17699990003" },
  ].each_with_index do |attrs, i|
    MbStaff.find_or_create_by!(mb_site_id: site_id, mb_staff_id: "STAFF-#{site_id}-#{i+1}") do |s|
      s.assign_attributes(attrs)
      s.image_url = ""
    end
  end

  # Class descriptions
  studio.class_configs.each_with_index do |config, i|
    MbClassDescription.find_or_create_by!(mb_site_id: site_id, mb_class_description_id: "DESC-#{site_id}-#{i+1}") do |d|
      d.name = config.class_name
      d.description = "A #{config.is_premium ? 'premium' : 'standard'} #{config.class_name.downcase} session focusing on technique, form, and mindful movement."
      d.duration_minutes = [45, 50, 60].sample
      d.category = config.is_premium ? "Premium" : "Group Fitness"
    end
  end

  # Classes
  staff = MbStaff.where(mb_site_id: site_id)
  MbClassDescription.where(mb_site_id: site_id).each_with_index do |desc, i|
    3.times do |j|
      start_time = (Date.today + j + 1).to_time + [9, 12, 17].sample.hours
      MbClass.find_or_create_by!(mb_site_id: site_id, mb_class_id: "CLASS-#{site_id}-#{i+1}-#{j+1}") do |c|
        c.mb_class_description_id = desc.mb_class_description_id
        c.mb_staff_id = staff.sample&.mb_staff_id || "STAFF-#{site_id}-1"
        c.start_datetime = start_time
        c.end_datetime = start_time + desc.duration_minutes.minutes
        c.max_capacity = [15, 20, 25].sample
        c.total_booked = rand(3..12)
        c.is_canceled = false
        c.location = "Studio #{['A', 'B', 'Main'].sample}"
      end
    end
  end

  # Clients
  member_users.first(8).each_with_index do |user, i|
    MbClient.find_or_create_by!(mb_site_id: site_id, mb_client_id: "CLIENT-#{site_id}-#{i+1}") do |c|
      c.first_name = user.first_name
      c.last_name = user.last_name
      c.email = "#{user.first_name.downcase}@example.com"
      c.phone = user.phone
      c.birth_date = Date.new(rand(1985..2000), rand(1..12), rand(1..28))
      c.gender = ["Female", "Male", "Non-binary"].sample
      c.city = "Berlin"
      c.state = "Berlin"
      c.zip = "10#{rand(115..999)}"
      c.address = "#{rand(1..200)} Friedrichstrasse"
      c.status = "Active"
      c.creation_date = rand(30..180).days.ago
    end

    # Client visits
    rand(1..4).times do |j|
      mb_class = MbClass.where(mb_site_id: site_id).sample
      next unless mb_class
      MbClientVisit.find_or_create_by!(
        mb_site_id: site_id,
        mb_client_id: "CLIENT-#{site_id}-#{i+1}",
        mb_visit_id: "VISIT-#{site_id}-#{i+1}-#{j+1}"
      ) do |v|
        v.mb_class_id = mb_class.mb_class_id
        v.arrival_datetime = rand(1..30).days.ago
        v.signed_in = true
        v.visit_type = "Class"
      end
    rescue ActiveRecord::RecordInvalid
      # skip
    end

    # Memberships
    MbMembership.find_or_create_by!(
      mb_site_id: site_id,
      mb_client_id: "CLIENT-#{site_id}-#{i+1}",
      mb_membership_id: "MEM-#{site_id}-#{i+1}"
    ) do |m|
      m.name = ["Monthly Unlimited", "10-Class Pack", "Annual Premium", "Drop-In"].sample
      m.active_date = rand(30..90).days.ago
      m.expiration_date = rand(30..180).days.from_now
      m.status = "Active"
      m.payment_amount = [29.99, 49.99, 79.99, 99.99, 149.99].sample
      m.remaining_sessions = rand(1..20)
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end

  # Purchases
  member_users.first(6).each_with_index do |user, i|
    rand(1..3).times do |j|
      MbPurchase.find_or_create_by!(
        mb_site_id: site_id,
        mb_client_id: "CLIENT-#{site_id}-#{i+1}",
        mb_purchase_id: "PUR-#{site_id}-#{i+1}-#{j+1}"
      ) do |p|
        p.description = ["Monthly Unlimited Membership", "10-Class Pack", "Drop-In Class", "Private Session", "Workshop: Breathwork"].sample
        p.amount = [15.00, 29.99, 49.99, 79.99, 120.00].sample
        p.sale_date = rand(1..60).days.ago
        p.payment_method = ["Credit Card", "Debit Card", "PayPal", "Cash"].sample
      end
    rescue ActiveRecord::RecordInvalid
      # skip
    end
  end

  # MindbodyClients (linking table)
  member_users.first(6).each_with_index do |user, i|
    MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "CLIENT-#{site_id}-#{i+1}") do |mc|
      mc.first_name = user.first_name
      mc.last_name = user.last_name
      mc.email = "#{user.first_name.downcase}@example.com"
      mc.phone = user.phone
    end
  rescue ActiveRecord::RecordInvalid
    # skip
  end
end
puts "Mindbody data seeded"

# ── Mindbody links (user ↔ MB client) ───────────────────────────────────────
member_users.first(6).each_with_index do |user, i|
  MindbodyLink.find_or_create_by!(user: user) do |ml|
    ml.mindbody_client_id = "CLIENT-123456-#{i+1}"
    ml.status = "linked"
    ml.linked_at = rand(10..60).days.ago
    ml.match_data = { confidence: rand(85..99), matched_by: "phone" }.to_json
  end
rescue ActiveRecord::RecordInvalid
  # skip
end
puts "Mindbody links seeded"

# ── Summary ──────────────────────────────────────────────────────────────────
puts "\n=== Demo data complete ==="
puts "Studios: #{Studio.count}"
puts "Members: #{User.where(admin: false).count}"
puts "Visits: #{Visit.count}"
puts "Bookings: #{Booking.count}"
puts "Stamp cards: #{StampCard.count}"
puts "Deal claims: #{DealClaim.count}"
puts "Reward redemptions: #{RewardRedemption.count}"
puts "Referrals: #{Referral.count}"
puts "Chats: #{Chat.count}"
puts "Messages: #{Message.count}"
puts "Notifications: #{Notification.count}"
puts "Broadcasts: #{Broadcast.count}"
puts "Notification templates: #{NotificationTemplate.count}"
puts "MB Staff: #{MbStaff.count}"
puts "MB Classes: #{MbClass.count}"
puts "MB Clients: #{MbClient.count}"
puts "MB Client Visits: #{MbClientVisit.count}"
puts "MB Memberships: #{MbMembership.count}"
puts "MB Purchases: #{MbPurchase.count}"
puts "Mindbody Links: #{MindbodyLink.count}"
