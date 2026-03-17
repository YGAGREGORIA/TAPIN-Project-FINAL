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
alice.update_columns(role: 1) if User.column_names.include?("role") && alice.role.to_s != "admin"
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
bob.update_columns(role: 0) if User.column_names.include?("role") && bob.role.to_s != "customer"
bob.update_columns(confirmed_at: Time.current) if User.column_names.include?("confirmed_at") && bob.confirmed_at.nil?

carol = User.find_or_create_by!(email: "carol@example.com") do |u|
  u.password = "Password123"
  u.first_name = "Carol"
  u.last_name = "Park"
  u.phone = 612345678
  u.last_visit_at = 1.week.ago
  u.confirmed_at = Time.current if u.respond_to?(:confirmed_at=)
end
carol.update_columns(role: 0) if User.column_names.include?("role") && carol.role.to_s != "customer"
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
  { first_name: "Mila",   last_name: "Fischer", email: "mila@example.com",   phone: 611000008, visits: 18, weeks_ago: 4 },
  { first_name: "Noah",   last_name: "Becker",  email: "noah@example.com",   phone: 611000009, visits: 9,  weeks_ago: 1 },
  { first_name: "Emma",   last_name: "Klein",   email: "emma@example.com",   phone: 611000010, visits: 14, weeks_ago: 2 },
  { first_name: "Leo",    last_name: "Wagner",  email: "leo@example.com",    phone: 611000011, visits: 6,  weeks_ago: 5 }
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
  u.update_columns(role: 0) if User.column_names.include?("role") && u.role.to_s != "customer"
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

Reward.where(studio: studio, name: "Merchandise Discount").destroy_all

Deal.find_or_create_by!(studio: studio, name: "Merchandise Discount") do |d|
  d.deal_type = "discount"
  d.discount_percent = 20
  d.usage_limit = 1
  d.expiry_days = 30
  d.active = true
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

# =============================================================================
# FAKE MINDBODY SYSTEM (mb_ tables)
# These replicate what Mindbody's API would return, so we can develop
# and test without a real Mindbody connection.
# =============================================================================

SITE_ID = "12345" # matches studio.mindbody_site_id

puts "Seeding Mindbody system — mb_clients..."

mb_client_data = [
  # These 5 match the existing mindbody_clients bridge table
  { id: "MB-1001", first: "Alice",    last: "Martin",  email: "alice@example.com",      phone: "611234567",  gender: "Female", birth: "1990-03-15", status: "Active",   created: 14.months.ago },
  { id: "MB-1002", first: "Bob",      last: "Chen",    email: "bob.chen@gmail.com",     phone: "619999999",  gender: "Male",   birth: "1988-07-22", status: "Active",   created: 11.months.ago },
  { id: "MB-1003", first: "Robert",   last: "Chen",    email: "robert.chen@gmail.com",  phone: "619876543",  gender: "Male",   birth: "1985-01-10", status: "Active",   created: 10.months.ago },
  { id: "MB-1004", first: "Carol",    last: "Park",    email: "carol.park@gmail.com",   phone: "612345678",  gender: "Female", birth: "1992-11-05", status: "Active",   created: 8.months.ago },
  { id: "MB-1005", first: "Caroline", last: "Parker",  email: "caroline.p@gmail.com",   phone: "612345678",  gender: "Female", birth: "1991-06-18", status: "Active",   created: 6.months.ago },
  # These 5 are Mindbody-only (haven't signed up for TapIn)
  { id: "MB-1006", first: "Derek",    last: "Hoffman", email: "derek.h@gmail.com",      phone: "615550101",  gender: "Male",   birth: "1987-09-30", status: "Active",   created: 18.months.ago },
  { id: "MB-1007", first: "Yuki",     last: "Tanaka",  email: "yuki.t@outlook.com",     phone: "615550102",  gender: "Female", birth: "1995-04-12", status: "Active",   created: 12.months.ago },
  { id: "MB-1008", first: "Raj",      last: "Mehta",   email: "raj.mehta@gmail.com",    phone: "615550103",  gender: "Male",   birth: "1993-08-20", status: "Active",   created: 9.months.ago },
  { id: "MB-1009", first: "Tanya",    last: "Brooks",  email: "tanya.b@yahoo.com",      phone: "615550104",  gender: "Female", birth: "1989-12-01", status: "Inactive", created: 20.months.ago },
  { id: "MB-1010", first: "Sam",      last: "Rivera",  email: "sam.rivera@gmail.com",   phone: "615550105",  gender: "Male",   birth: "1996-02-14", status: "Active",   created: 4.months.ago },
]

mb_clients = mb_client_data.map do |d|
  Mb::Client.find_or_create_by!(mb_site_id: SITE_ID, mb_client_id: d[:id]) do |c|
    c.first_name = d[:first]
    c.last_name = d[:last]
    c.email = d[:email]
    c.phone = d[:phone]
    c.gender = d[:gender]
    c.birth_date = Date.parse(d[:birth])
    c.status = d[:status]
    c.creation_date = d[:created]
    c.address = "#{rand(100..999)} Main St"
    c.city = "Fitville"
    c.state = "CA"
    c.zip = "90210"
  end
end

puts "Seeding Mindbody system — mb_staff..."

staff_data = [
  { id: "STF-001", first: "Sarah",  last: "Chen",   email: "sarah.chen@tapinfitness.com",  bio: "RYT-500 certified yoga instructor with 8 years of experience. Specializes in vinyasa and restorative yoga." },
  { id: "STF-002", first: "Maya",   last: "Patel",  email: "maya.patel@tapinfitness.com",  bio: "Passionate yoga teacher focused on mindfulness and breath work. Teaches all levels." },
  { id: "STF-003", first: "Jordan", last: "Blake",  email: "jordan.blake@tapinfitness.com", bio: "Former collegiate athlete turned HIIT specialist. High energy, no excuses." },
  { id: "STF-004", first: "Marcus", last: "Lee",    email: "marcus.lee@tapinfitness.com",  bio: "ACE-certified personal trainer and group fitness instructor. Loves pushing limits." },
  { id: "STF-005", first: "Emma",   last: "Torres", email: "emma.torres@tapinfitness.com", bio: "Pilates Method Alliance certified. 6 years teaching mat and reformer Pilates." },
]

mb_staff = staff_data.map do |d|
  Mb::Staff.find_or_create_by!(mb_site_id: SITE_ID, mb_staff_id: d[:id]) do |s|
    s.first_name = d[:first]
    s.last_name = d[:last]
    s.email = d[:email]
    s.phone = "61555#{rand(1000..9999)}"
    s.bio = d[:bio]
  end
end

sarah, maya, jordan, marcus, emma = mb_staff

puts "Seeding Mindbody system — mb_class_descriptions..."

cd_yoga = Mb::ClassDescription.find_or_create_by!(mb_site_id: SITE_ID, mb_class_description_id: "CD-101") do |d|
  d.name = "Morning Yoga"
  d.description = "Flow through a series of gentle postures designed to build strength and flexibility. Perfect for all levels."
  d.category = "Yoga"
  d.duration_minutes = 60
end

cd_hiit = Mb::ClassDescription.find_or_create_by!(mb_site_id: SITE_ID, mb_class_description_id: "CD-102") do |d|
  d.name = "HIIT Blast"
  d.description = "High-intensity interval training that torches calories and builds endurance. Get ready to sweat!"
  d.category = "Cardio"
  d.duration_minutes = 45
end

cd_pilates = Mb::ClassDescription.find_or_create_by!(mb_site_id: SITE_ID, mb_class_description_id: "CD-103") do |d|
  d.name = "Pilates Core"
  d.description = "Core-focused movements to improve posture, stability, and total-body strength. Low impact, high reward."
  d.category = "Pilates"
  d.duration_minutes = 60
end

puts "Seeding Mindbody system — mb_classes (schedule)..."

# Build 4 weeks of historical classes + 1 week of future classes
mb_schedule = [
  { day_of_week: 0, hour: 7,  desc: cd_yoga,    staff: sarah,  name: "Morning Yoga" },
  { day_of_week: 0, hour: 12, desc: cd_pilates,  staff: emma,   name: "Pilates Core" },
  { day_of_week: 0, hour: 18, desc: cd_hiit,     staff: jordan, name: "HIIT Blast" },
  { day_of_week: 1, hour: 6,  desc: cd_hiit,     staff: marcus, name: "HIIT Blast" },
  { day_of_week: 1, hour: 9,  desc: cd_yoga,     staff: maya,   name: "Morning Yoga" },
  { day_of_week: 1, hour: 17, desc: cd_pilates,  staff: emma,   name: "Pilates Core" },
  { day_of_week: 2, hour: 7,  desc: cd_yoga,     staff: sarah,  name: "Morning Yoga" },
  { day_of_week: 2, hour: 19, desc: cd_hiit,     staff: jordan, name: "HIIT Blast" },
  { day_of_week: 3, hour: 8,  desc: cd_pilates,  staff: emma,   name: "Pilates Core" },
  { day_of_week: 3, hour: 12, desc: cd_yoga,     staff: maya,   name: "Morning Yoga" },
  { day_of_week: 3, hour: 18, desc: cd_hiit,     staff: marcus, name: "HIIT Blast" },
  { day_of_week: 4, hour: 7,  desc: cd_yoga,     staff: sarah,  name: "Morning Yoga" },
  { day_of_week: 4, hour: 10, desc: cd_hiit,     staff: jordan, name: "HIIT Blast" },
  { day_of_week: 5, hour: 9,  desc: cd_yoga,     staff: maya,   name: "Morning Yoga" },
  { day_of_week: 5, hour: 11, desc: cd_pilates,  staff: emma,   name: "Pilates Core" },
  { day_of_week: 5, hour: 17, desc: cd_hiit,     staff: marcus, name: "HIIT Blast" },
  { day_of_week: 6, hour: 8,  desc: cd_yoga,     staff: sarah,  name: "Morning Yoga" },
  { day_of_week: 6, hour: 10, desc: cd_pilates,  staff: emma,   name: "Pilates Core" },
]

mb_all_classes = []
class_counter = 0

(-4..1).each do |week_offset|
  week_start = Date.today.beginning_of_week + (week_offset * 7)

  mb_schedule.each do |s|
    class_date = week_start + s[:day_of_week]
    start_dt = class_date.to_datetime.change(hour: s[:hour])
    next if start_dt > 1.week.from_now # don't go too far into future

    class_counter += 1
    duration = s[:desc].duration_minutes || 60
    booked = week_offset < 0 ? rand(5..15) : rand(0..8)

    klass = Mb::Klass.find_or_create_by!(mb_site_id: SITE_ID, mb_class_id: "CLS-#{class_counter.to_s.rjust(4, '0')}") do |k|
      k.class_description = s[:desc]
      k.staff = s[:staff]
      k.start_datetime = start_dt
      k.end_datetime = start_dt + duration.minutes
      k.max_capacity = duration == 45 ? 15 : 20
      k.total_booked = booked
      k.is_canceled = false
      k.location = "Studio A"
    end

    mb_all_classes << { klass: klass, week_offset: week_offset, desc: s[:desc] }
  end
end

puts "Seeding Mindbody system — mb_client_visits..."

# Historical classes only (past weeks)
past_classes = mb_all_classes.select { |c| c[:week_offset] < 0 }
visit_counter = 0

# Distribute visits: Alice ~10, Bob ~9, Carol ~23, others varied
client_visit_targets = {
  mb_clients[0] => 10,  # Alice
  mb_clients[1] => 9,   # Bob
  mb_clients[3] => 23,  # Carol
  mb_clients[5] => 14,  # Derek (MB-only)
  mb_clients[6] => 8,   # Yuki
  mb_clients[7] => 6,   # Raj
  mb_clients[9] => 3,   # Sam
}

client_visit_targets.each do |client, target_visits|
  shuffled = past_classes.shuffle.first([target_visits, past_classes.size].min)
  shuffled.each do |cls|
    visit_counter += 1
    Mb::ClientVisit.find_or_create_by!(mb_site_id: SITE_ID, mb_visit_id: "VIS-#{visit_counter.to_s.rjust(5, '0')}") do |v|
      v.client = client
      v.klass = cls[:klass]
      v.visit_type = "class"
      v.signed_in = true
      v.arrival_datetime = cls[:klass].start_datetime - rand(0..10).minutes
    end
  end
end

puts "Seeding Mindbody system — mb_memberships..."

membership_types = [
  { name: "Unlimited Monthly",  amount: 149.00, sessions: nil },
  { name: "10-Class Pack",      amount: 180.00, sessions: 10 },
  { name: "Drop-In Single",     amount: 25.00,  sessions: 1 },
]

membership_counter = 0

[
  { client: mb_clients[0], type: 0, status: "Active",   active: 6.months.ago },  # Alice — Unlimited
  { client: mb_clients[1], type: 1, status: "Active",   active: 3.months.ago },  # Bob — 10-pack
  { client: mb_clients[3], type: 0, status: "Active",   active: 8.months.ago },  # Carol — Unlimited
  { client: mb_clients[5], type: 0, status: "Active",   active: 12.months.ago }, # Derek — Unlimited
  { client: mb_clients[6], type: 1, status: "Active",   active: 2.months.ago },  # Yuki — 10-pack
  { client: mb_clients[7], type: 1, status: "Active",   active: 4.months.ago },  # Raj — 10-pack
  { client: mb_clients[8], type: 0, status: "Expired",  active: 18.months.ago }, # Tanya — Expired
  { client: mb_clients[9], type: 2, status: "Active",   active: 1.month.ago },   # Sam — Drop-in
  { client: mb_clients[2], type: 2, status: "Active",   active: 5.months.ago },  # Robert — Drop-in
  { client: mb_clients[4], type: 1, status: "Active",   active: 3.months.ago },  # Caroline — 10-pack
].each do |m|
  membership_counter += 1
  mt = membership_types[m[:type]]
  active_date = m[:active].to_date
  exp_date = mt[:sessions].nil? ? active_date + 1.month : active_date + 6.months

  Mb::Membership.find_or_create_by!(mb_site_id: SITE_ID, mb_membership_id: "MEM-#{membership_counter.to_s.rjust(4, '0')}") do |mem|
    mem.client = m[:client]
    mem.name = mt[:name]
    mem.payment_amount = mt[:amount]
    mem.remaining_sessions = mt[:sessions] ? [mt[:sessions] - rand(0..5), 0].max : nil
    mem.active_date = active_date
    mem.expiration_date = m[:status] == "Expired" ? 6.months.ago.to_date : exp_date
    mem.status = m[:status]
  end
end

puts "Seeding Mindbody system — mb_purchases..."

purchase_counter = 0

[
  { client: mb_clients[0], desc: "Unlimited Monthly — Mar 2026", amount: 149.00, method: "Credit Card", date: 1.month.ago },
  { client: mb_clients[0], desc: "Unlimited Monthly — Feb 2026", amount: 149.00, method: "Credit Card", date: 2.months.ago },
  { client: mb_clients[1], desc: "10-Class Pack",                amount: 180.00, method: "Credit Card", date: 3.months.ago },
  { client: mb_clients[3], desc: "Unlimited Monthly — Mar 2026", amount: 149.00, method: "Credit Card", date: 1.month.ago },
  { client: mb_clients[3], desc: "Unlimited Monthly — Feb 2026", amount: 149.00, method: "Credit Card", date: 2.months.ago },
  { client: mb_clients[3], desc: "Unlimited Monthly — Jan 2026", amount: 149.00, method: "Credit Card", date: 3.months.ago },
  { client: mb_clients[5], desc: "Unlimited Monthly — Mar 2026", amount: 149.00, method: "Credit Card", date: 1.month.ago },
  { client: mb_clients[6], desc: "10-Class Pack",                amount: 180.00, method: "Debit Card",  date: 2.months.ago },
  { client: mb_clients[7], desc: "10-Class Pack",                amount: 180.00, method: "Credit Card", date: 4.months.ago },
  { client: mb_clients[9], desc: "Drop-In Single",               amount: 25.00,  method: "Apple Pay",   date: 3.weeks.ago },
  { client: mb_clients[9], desc: "Drop-In Single",               amount: 25.00,  method: "Apple Pay",   date: 1.week.ago },
  { client: mb_clients[0], desc: "Water Bottle — TAPIN Branded", amount: 18.00,  method: "Credit Card", date: 5.weeks.ago },
  { client: mb_clients[3], desc: "Yoga Mat — Premium",           amount: 45.00,  method: "Credit Card", date: 6.weeks.ago },
  { client: mb_clients[5], desc: "Protein Shake",                amount: 8.00,   method: "Cash",        date: 2.weeks.ago },
  { client: mb_clients[6], desc: "Grip Socks",                   amount: 12.00,  method: "Debit Card",  date: 3.weeks.ago },
].each do |p|
  purchase_counter += 1
  Mb::Purchase.find_or_create_by!(mb_site_id: SITE_ID, mb_purchase_id: "PUR-#{purchase_counter.to_s.rjust(5, '0')}") do |pur|
    pur.client = p[:client]
    pur.description = p[:desc]
    pur.amount = p[:amount]
    pur.payment_method = p[:method]
    pur.sale_date = p[:date]
  end
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
puts "Fake Mindbody system (mb_ tables):"
puts "  #{Mb::Client.count} clients, #{Mb::Staff.count} staff, #{Mb::ClassDescription.count} class types"
puts "  #{Mb::Klass.count} scheduled classes, #{Mb::ClientVisit.count} attendance records"
puts "  #{Mb::Membership.count} memberships, #{Mb::Purchase.count} purchases"
puts ""
puts "Admin pages:"
puts "  /admin — Dashboard"
puts "  /admin/mindbody_matches — Bob pending, Alice linked, Carol conflict"
