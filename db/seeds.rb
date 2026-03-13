# Idempotent seeds — safe to run multiple times without duplicating data.
# Uses find_or_create_by so re-running won't crash on existing records.

# Suppress job-enqueuing callbacks during seeding (SolidQueue may not be available)
if defined?(Visit)
  Visit.skip_callback(:create, :after, :enqueue_mindbody_match) if Visit.method_defined?(:enqueue_mindbody_match)
  Visit.skip_callback(:create, :after, :notify_reward_unlocked) if Visit.method_defined?(:notify_reward_unlocked)
  Visit.skip_callback(:create, :after, :complete_referral_if_first_visit) if Visit.method_defined?(:complete_referral_if_first_visit)
end
Rails.application.config.active_job.queue_adapter = :async

# Skip Devise confirmation emails during seeding (no SMTP on Heroku one-off dynos)
if User.method_defined?(:send_on_create_confirmation_instructions)
  User.skip_callback(:commit, :after, :send_on_create_confirmation_instructions)
end

puts "Seeding users..."

alice = User.find_or_create_by!(email: "alice@example.com") do |u|
  u.password = "Password123"
  u.first_name = "Alice"
  u.last_name = "Martin"
  u.phone = 611234567
  u.last_visit_at = 1.day.ago
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
alice.update_columns(admin: true) if alice.respond_to?(:admin) && User.column_names.include?("admin")
alice.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && alice.confirmed_at.nil?

bob = User.find_or_create_by!(email: "bob@example.com") do |u|
  u.password = "Password123"
  u.first_name = "Bob"
  u.last_name = "Chen"
  u.phone = 619876543
  u.referred_by = "alice@example.com"
  u.last_visit_at = 2.days.ago
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
bob.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && bob.confirmed_at.nil?

carol = User.find_or_create_by!(email: "carol@example.com") do |u|
  u.password = "Password123"
  u.first_name = "Carol"
  u.last_name = "Park"
  u.phone = 612345678
  u.last_visit_at = 1.week.ago
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
carol.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && carol.confirmed_at.nil?

owner = User.find_or_create_by!(email: "owner@tapinstudio.com") do |u|
  u.password = "Password123"
  u.first_name = "Sara"
  u.last_name = "Lopez"
  u.phone = 610001111
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
owner.update_columns(admin: true) if owner.respond_to?(:admin) && User.column_names.include?("admin")
owner.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && owner.confirmed_at.nil?
# Also set role to admin if the column exists
owner.update_columns(role: 1) if User.column_names.include?("role") && owner.role.to_s != "admin"

demo_members = [
  { first_name: "Lena",   last_name: "Rossi",   email: "lena@example.com",   phone: 611000001, visits: 7,  weeks_ago: 3 },
  { first_name: "Marcus", last_name: "Webb",    email: "marcus@example.com", phone: 611000002, visits: 15, weeks_ago: 1 },
  { first_name: "Priya",  last_name: "Sharma",  email: "priya@example.com",  phone: 611000003, visits: 3,  weeks_ago: 2 },
  { first_name: "Jaden",  last_name: "Torres",  email: "jaden@example.com",  phone: 611000004, visits: 20, weeks_ago: 1 },
  { first_name: "Sofia",  last_name: "Nguyen",  email: "sofia@example.com",  phone: 611000005, visits: 1,  weeks_ago: 0 },
  { first_name: "Owen",   last_name: "Blake",   email: "owen@example.com",   phone: 611000006, visits: 12, weeks_ago: 2 },
  { first_name: "Aisha",  last_name: "Patel",   email: "aisha@example.com",  phone: 611000007, visits: 5,  weeks_ago: 1 },
]

demo_users = demo_members.map do |m|
  u = User.find_or_create_by!(email: m[:email]) do |user|
    user.password = "Password123"
    user.first_name = m[:first_name]
    user.last_name = m[:last_name]
    user.phone = m[:phone]
    user.last_visit_at = m[:weeks_ago].weeks.ago
    user.confirmed_at = Time.current if user.respond_to?(:confirmed_at=)
  end
  u.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && u.confirmed_at.nil?
  u
end

puts "Seeding studio..."

studio = Studio.find_or_create_by!(slug: "tapin-fitness") do |s|
  s.user = alice
  s.name = "TAPIN Fitness"
  s.mindbody_site_id = "12345"
  s.mindbody_api_key = "test-api-key-abc"
  s.active = true
end

StudioBrand.find_or_create_by!(studio: studio) do |b|
  b.primary_color = "#FF5733"
  b.secondary_color = "#33C1FF"
  b.background_color = "#F5F5F5"
  b.text_color = "#222222"
  b.logo_url = "https://example.com/logo.png"
  b.font_heading = "Montserrat"
  b.font_body = "Open Sans"
  b.brand_tone = "energetic"
  b.tagline = "Tap in. Level up."
end

puts "Seeding class configs..."

yoga = ClassConfig.find_or_create_by!(studio: studio, mindbody_class_id: 101) do |c|
  c.class_name = "Morning Yoga"
  c.point_value = 10
  c.is_premium = false
end

hiit = ClassConfig.find_or_create_by!(studio: studio, mindbody_class_id: 102) do |c|
  c.class_name = "HIIT Blast"
  c.point_value = 20
  c.is_premium = true
end

pilates = ClassConfig.find_or_create_by!(studio: studio, mindbody_class_id: 103) do |c|
  c.class_name = "Pilates Core"
  c.point_value = 15
  c.is_premium = false
end

puts "Seeding studio classes (schedule)..."

teachers = {
  yoga:    ["Sarah Chen", "Maya Patel"],
  hiit:    ["Jordan Blake", "Marcus Lee"],
  pilates: ["Emma Torres"]
}

yoga_desc    = "Flow through a series of gentle postures designed to build strength and flexibility. Perfect for all levels."
hiit_desc    = "High-intensity interval training that torches calories and builds endurance. Get ready to sweat!"
pilates_desc = "Core-focused movements to improve posture, stability, and total-body strength. Low impact, high reward."

[
  { day: 0, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],    config: yoga,    name: "Morning Yoga" },
  { day: 0, hour: 12, type: "pilates", teacher: teachers[:pilates][0], config: pilates, name: "Pilates Core" },
  { day: 0, hour: 18, type: "hiit",    teacher: teachers[:hiit][0],    config: hiit,    name: "HIIT Blast" },
  { day: 1, hour: 6,  type: "hiit",    teacher: teachers[:hiit][1],    config: hiit,    name: "HIIT Blast" },
  { day: 1, hour: 9,  type: "yoga",    teacher: teachers[:yoga][1],    config: yoga,    name: "Morning Yoga" },
  { day: 1, hour: 17, type: "pilates", teacher: teachers[:pilates][0], config: pilates, name: "Pilates Core" },
  { day: 2, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],    config: yoga,    name: "Morning Yoga" },
  { day: 2, hour: 19, type: "hiit",    teacher: teachers[:hiit][0],    config: hiit,    name: "HIIT Blast" },
  { day: 3, hour: 8,  type: "pilates", teacher: teachers[:pilates][0], config: pilates, name: "Pilates Core" },
  { day: 3, hour: 12, type: "yoga",    teacher: teachers[:yoga][1],    config: yoga,    name: "Morning Yoga" },
  { day: 3, hour: 18, type: "hiit",    teacher: teachers[:hiit][1],    config: hiit,    name: "HIIT Blast" },
  { day: 4, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],    config: yoga,    name: "Morning Yoga" },
  { day: 4, hour: 10, type: "hiit",    teacher: teachers[:hiit][0],    config: hiit,    name: "HIIT Blast" },
  { day: 5, hour: 9,  type: "yoga",    teacher: teachers[:yoga][1],    config: yoga,    name: "Morning Yoga" },
  { day: 5, hour: 11, type: "pilates", teacher: teachers[:pilates][0], config: pilates, name: "Pilates Core" },
  { day: 5, hour: 17, type: "hiit",    teacher: teachers[:hiit][1],    config: hiit,    name: "HIIT Blast" },
  { day: 6, hour: 8,  type: "yoga",    teacher: teachers[:yoga][0],    config: yoga,    name: "Morning Yoga" },
  { day: 6, hour: 10, type: "pilates", teacher: teachers[:pilates][0], config: pilates, name: "Pilates Core" }
].each do |c|
  scheduled = Date.today.advance(days: c[:day]).change(hour: c[:hour], min: 0)
  StudioClass.find_or_create_by!(studio: studio, class_config: c[:config], scheduled_at: scheduled) do |sc|
    sc.name = c[:name]
    sc.teacher_name = c[:teacher]
    sc.description = case c[:type]
                     when "yoga" then yoga_desc
                     when "hiit" then hiit_desc
                     when "pilates" then pilates_desc
                     end
    sc.class_type = c[:type]
    sc.duration_minutes = c[:type] == "hiit" ? 45 : 60
    sc.capacity = c[:type] == "hiit" ? 15 : 20
    sc.spots_taken = rand(0..10)
  end
end

puts "Seeding deals..."

deal1 = Deal.find_or_create_by!(studio: studio, name: "First Visit Free") do |d|
  d.deal_type = "discount"
  d.discount_percent = 100
  d.trigger_condition = "first_visit"
  d.usage_limit = 1
  d.expiry_days = 30
  d.active = true
end

deal2 = Deal.find_or_create_by!(studio: studio, name: "Refer a Friend — 10% Off") do |d|
  d.deal_type = "discount"
  d.discount_percent = 10
  d.trigger_condition = "referral"
  d.usage_limit = 1
  d.expiry_days = 14
  d.active = true
end

puts "Seeding rewards..."

free_class_reward = Reward.find_or_create_by!(studio: studio, name: "Free Class") do |r|
  r.reward_type = :free_class
  r.points_cost = 0
  r.image_url = "https://example.com/free-class.png"
  r.description = "Unlock one free class after 10 visits."
  r.active = true
end

Reward.find_or_create_by!(studio: studio, name: "Guest Pass") do |r|
  r.reward_type = :free_class
  r.points_cost = 0
  r.image_url = "https://example.com/guest-pass.png"
  r.description = "Bring a friend for free — one guest pass on us."
  r.active = true
end

Reward.find_or_create_by!(studio: studio, name: "Merchandise Discount") do |r|
  r.reward_type = :free_class
  r.points_cost = 0
  r.image_url = "https://example.com/merch.png"
  r.description = "20% off any item in our studio shop."
  r.active = true
end

puts "Seeding visits..."

def seed_visits(user, studio, configs, count)
  return if user.visits.where(studio: studio).count >= count

  existing = user.visits.where(studio: studio).count
  (existing...count).each do |i|
    config = configs[i % configs.length]
    Visit.create!(
      user: user,
      studio: studio,
      class_config: config,
      points_earned: config.point_value,
      visited_at: (count - i).weeks.ago
    )
  end
end

all_configs = [yoga, hiit, pilates, yoga, hiit, pilates, yoga, hiit, pilates, yoga,
               pilates, yoga, hiit, pilates, yoga, hiit, pilates, yoga, pilates, hiit,
               yoga, pilates, hiit]

seed_visits(alice, studio, all_configs, 10)
seed_visits(bob, studio, all_configs, 9)
seed_visits(carol, studio, all_configs, 23)

demo_members.each_with_index do |m, idx|
  seed_visits(demo_users[idx], studio, all_configs, m[:visits])
end

puts "Seeding bookings..."

unless Booking.exists?(user: alice, mindbody_booking_id: 9001)
  alice_yoga_class = StudioClass.find_by(studio: studio, class_type: "yoga",
                                          scheduled_at: Date.today.advance(days: 2).change(hour: 7, min: 0))
  Booking.create!(
    user: alice, studio: studio, studio_class: alice_yoga_class,
    mindbody_booking_id: 9001, class_name: "Morning Yoga",
    class_time: 2.days.from_now.change(hour: 8), status: true, booked_at: 1.day.ago
  )
end

unless Booking.exists?(user: bob, mindbody_booking_id: 9002)
  bob_hiit_class = StudioClass.find_by(studio: studio, class_type: "hiit",
                                        scheduled_at: Date.today.advance(days: 3).change(hour: 18, min: 0))
  Booking.create!(
    user: bob, studio: studio, studio_class: bob_hiit_class,
    mindbody_booking_id: 9002, class_name: "HIIT Blast",
    class_time: 3.days.from_now.change(hour: 18), status: true, booked_at: Time.current
  )
end

unless Booking.exists?(user: carol, mindbody_booking_id: 9003)
  Booking.create!(
    user: carol, studio: studio,
    mindbody_booking_id: 9003, class_name: "Pilates Core",
    class_time: 1.day.from_now.change(hour: 10), status: true, booked_at: Time.current
  )
end

unless Booking.exists?(user: carol, mindbody_booking_id: 9004)
  carol_hiit_class = StudioClass.find_by(studio: studio, class_type: "hiit",
                                          scheduled_at: Date.today.advance(days: 4).change(hour: 10, min: 0))
  Booking.create!(
    user: carol, studio: studio, studio_class: carol_hiit_class,
    mindbody_booking_id: 9004, class_name: "HIIT Blast",
    class_time: 5.days.from_now.change(hour: 18), status: true, booked_at: Time.current
  )
end

puts "Seeding deal claims..."

claim_attrs = { studio: studio }
claim_attrs[:active] = true if DealClaim.column_names.include?("active")

DealClaim.find_or_create_by!(code: "FIRST-ALICE-001") do |dc|
  dc.user = alice
  dc.deal = deal1
  dc.studio = studio
  dc.claimed_at = 10.weeks.ago
  dc.active = true if dc.respond_to?(:active=)
end

DealClaim.find_or_create_by!(code: "FIRST-BOB-001") do |dc|
  dc.user = bob
  dc.deal = deal1
  dc.studio = studio
  dc.claimed_at = 9.weeks.ago
  dc.active = true if dc.respond_to?(:active=)
end

DealClaim.find_or_create_by!(code: "FIRST-CAROL-001") do |dc|
  dc.user = carol
  dc.deal = deal1
  dc.studio = studio
  dc.claimed_at = 5.weeks.ago
  dc.active = true if dc.respond_to?(:active=)
end

DealClaim.find_or_create_by!(code: "10OFF-CAROL-001") do |dc|
  dc.user = carol
  dc.deal = deal2
  dc.studio = studio
  dc.claimed_at = 1.week.ago
  dc.active = true if dc.respond_to?(:active=)
end

puts "Seeding reward redemptions..."

RewardRedemption.find_or_create_by!(code: "FREE-EXPIRED01") do |r|
  r.user = alice
  r.reward = free_class_reward
  r.studio = studio
  r.redeemed_at = 45.days.ago
  r.expiry_days = 30
  r.point_sent = 0 if r.respond_to?(:point_sent=)
  r.point_spent = 0 if r.respond_to?(:point_spent=)
  r.status = false
end

RewardRedemption.find_or_create_by!(code: "FREE-CAROL-001") do |r|
  r.user = carol
  r.reward = free_class_reward
  r.studio = studio
  r.redeemed_at = 3.days.ago
  r.expiry_days = 30
  r.point_sent = 0 if r.respond_to?(:point_sent=)
  r.point_spent = 0 if r.respond_to?(:point_spent=)
  r.status = true
end

puts "Seeding chats..."

chat1 = Chat.find_or_create_by!(user: alice, studio: studio) do |c|
  c.status = true
end

chat2 = Chat.find_or_create_by!(user: bob, studio: studio) do |c|
  c.status = true
end

chat3 = Chat.find_or_create_by!(user: carol, studio: studio) do |c|
  c.status = true
end

puts "Seeding messages..."

if chat1.messages.empty?
  Message.create!(chat: chat1, role: "user", content: "Hi! When is the next yoga class?")
  Message.create!(chat: chat1, role: "assistant", content: "The next Morning Yoga class is at 8am in 2 days. Would you like to book it?")
end

if chat2.messages.empty?
  Message.create!(chat: chat2, role: "user", content: "How many more visits until I get a free class?")
  Message.create!(chat: chat2, role: "assistant", content: "You have 9 visits — just 1 more to unlock your free class!")
end

if chat3.messages.empty?
  Message.create!(chat: chat3, role: "user", content: "I just hit 23 visits! Can I use my free class reward this week?")
  Message.create!(chat: chat3, role: "assistant", content: "Congrats on 23 visits! Yes, your free class reward is ready to redeem — just tap 'Redeem Now' on your dashboard.")
end

puts "Seeding Mindbody clients..."

MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "MB-1001") do |c|
  c.first_name = "Alice"
  c.last_name = "Martin"
  c.phone = "611234567"
  c.email = "alice@example.com"
end

MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "MB-1002") do |c|
  c.first_name = "Bob"
  c.last_name = "Chen"
  c.phone = "619999999"
  c.email = "bob.chen@gmail.com"
end

MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "MB-1003") do |c|
  c.first_name = "Robert"
  c.last_name = "Chen"
  c.phone = "619876543"
  c.email = "robert.chen@gmail.com"
end

MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "MB-1004") do |c|
  c.first_name = "Carol"
  c.last_name = "Park"
  c.phone = "612345678"
  c.email = "carol.park@gmail.com"
end

MindbodyClient.find_or_create_by!(studio: studio, mindbody_client_id: "MB-1005") do |c|
  c.first_name = "Caroline"
  c.last_name = "Parker"
  c.phone = "612345678"
  c.email = "caroline.p@gmail.com"
end

puts "Seeding Mindbody links..."

alice_link = MindbodyLink.find_or_initialize_by(user: alice)
alice_link.update!(status: "linked", mindbody_client_id: "MB-1001",
                   match_data: { matched_by: "phone", name: "Alice Martin" })

bob_link = MindbodyLink.find_or_initialize_by(user: bob)
bob_link.update!(status: "pending", mindbody_client_id: "MB-1002",
                 match_data: { matched_by: "name", name: "Bob Chen" })

carol_link = MindbodyLink.find_or_initialize_by(user: carol)
carol_link.update!(status: "conflict",
                   match_data: [
                     { mindbody_client_id: "MB-1004", name: "Carol Park", phone: "612345678" },
                     { mindbody_client_id: "MB-1005", name: "Caroline Parker", phone: "612345678" }
                   ])

puts "Updating user point totals..."

[alice, bob, carol, *demo_users].each do |user|
  earned = user.visits.sum(:points_earned).to_i
  user.update_columns(
    available_points: earned,
    total_points: earned,
    total_visits: user.visits.count
  )
end

puts ""
puts "Done! Seed data created successfully."
puts ""
puts "Login credentials:"
puts "  Password for all users: Password123"
puts ""
puts "Test scenarios:"
puts "  alice@example.com       — admin, 10 visits, reward available"
puts "  bob@example.com         — 9 visits, 1 visit remaining"
puts "  carol@example.com       — 23 visits, 1 available reward, 2 bookings, 2 deal claims"
puts "  owner@tapinstudio.com   — studio owner/admin account"
puts "  lena/marcus/priya/...   — 7 demo members with varied visit history"
puts ""
puts "Admin pages:"
puts "  /admin — Dashboard"
puts "  /admin/mindbody_matches — Bob pending, Alice linked, Carol conflict"
