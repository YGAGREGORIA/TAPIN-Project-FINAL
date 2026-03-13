# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Suppress job-enqueuing callbacks during seeding (SolidQueue may not be available)
Visit.skip_callback(:create, :after, :enqueue_mindbody_match) if Visit.method_defined?(:enqueue_mindbody_match)
Visit.skip_callback(:create, :after, :notify_reward_unlocked) if Visit.method_defined?(:notify_reward_unlocked)

puts "Cleaning database..."
Notification.destroy_all if defined?(Notification)
PushSubscription.destroy_all if defined?(PushSubscription)
NotificationTemplate.destroy_all if defined?(NotificationTemplate)
Broadcast.destroy_all if defined?(Broadcast)
MindbodyClient.destroy_all
MindbodyLink.destroy_all
Referral.destroy_all
Message.destroy_all
Chat.destroy_all
RewardRedemption.destroy_all
Reward.destroy_all
DealClaim.destroy_all
Deal.destroy_all
Visit.destroy_all
Booking.destroy_all
StudioClass.destroy_all
ClassConfig.destroy_all
StudioBrand.destroy_all
Studio.destroy_all
User.destroy_all

puts "Creating users..."

# alice: 10 visits → reward available (10/10, 1 milestone, 0 redemptions)
alice = User.create!(
  email: "alice@example.com",
  password: "password",
  first_name: "Alice",
  last_name: "Martin",
  phone: 611234567,
  referred_by: nil,
  last_visit_at: 1.day.ago
)

# bob: 9 visits → almost there (9/10)
bob = User.create!(
  email: "bob@example.com",
  password: "password",
  first_name: "Bob",
  last_name: "Chen",
  phone: 619876543,
  referred_by: "alice@example.com",
  last_visit_at: 2.days.ago
)

# carol: 20 visits → 2 milestones, 1 redemption used, 1 available reward, 2 deals claimed, 2 upcoming bookings
carol = User.create!(
  email: "carol@example.com",
  password: "password",
  first_name: "Carol",
  last_name: "Park",
  phone: 612345678,
  referred_by: nil,
  last_visit_at: 1.week.ago
)

owner = User.create!(
  email: "owner@tapinstudio.com",
  password: "password",
  first_name: "Sara",
  last_name: "Lopez",
  phone: 610001111,
  referred_by: nil,
  last_visit_at: nil,
  role: :admin
)

puts "Creating studios..."

studio = Studio.create!(
  user: owner,
  name: "TAPIN Fitness",
  slug: "tapin-fitness",
  mindbody_site_id: "12345",
  mindbody_api_key: "test-api-key-abc",
  active: true
)

puts "Creating studio brand..."

StudioBrand.create!(
  studio: studio,
  primary_color: "#FF5733",
  secondary_color: "#33C1FF",
  background_color: "#F5F5F5",
  text_color: "#222222",
  logo_url: "https://example.com/logo.png",
  font_heading: "Montserrat",
  font_body: "Open Sans",
  brand_tone: "energetic",
  tagline: "Tap in. Level up.",
  raw_extraction: nil
)

puts "Creating class configs..."

yoga = ClassConfig.create!(
  studio: studio,
  mindbody_class_id: 101,
  class_name: "Morning Yoga",
  point_value: 10,
  is_premium: false
)

hiit = ClassConfig.create!(
  studio: studio,
  mindbody_class_id: 102,
  class_name: "HIIT Blast",
  point_value: 20,
  is_premium: true
)

pilates = ClassConfig.create!(
  studio: studio,
  mindbody_class_id: 103,
  class_name: "Pilates Core",
  point_value: 15,
  is_premium: false
)

puts "Creating studio classes (schedule)..."

teachers = {
  yoga:    [ "Sarah Chen", "Maya Patel" ],
  hiit:    [ "Jordan Blake", "Marcus Lee" ],
  pilates: [ "Emma Torres" ]
}

yoga_desc    = "Flow through a series of gentle postures designed to build strength and flexibility. Perfect for all levels."
hiit_desc    = "High-intensity interval training that torches calories and builds endurance. Get ready to sweat!"
pilates_desc = "Core-focused movements to improve posture, stability, and total-body strength. Low impact, high reward."

# Spread classes across the next 7 days
[
  { day: 0, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],    config: yoga,    name: "Morning Yoga" },
  { day: 0, hour: 12, type: "pilates", teacher: teachers[:pilates][0],  config: pilates, name: "Pilates Core" },
  { day: 0, hour: 18, type: "hiit",    teacher: teachers[:hiit][0],     config: hiit,    name: "HIIT Blast" },
  { day: 1, hour: 6,  type: "hiit",    teacher: teachers[:hiit][1],     config: hiit,    name: "HIIT Blast" },
  { day: 1, hour: 9,  type: "yoga",    teacher: teachers[:yoga][1],     config: yoga,    name: "Morning Yoga" },
  { day: 1, hour: 17, type: "pilates", teacher: teachers[:pilates][0],  config: pilates, name: "Pilates Core" },
  { day: 2, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],     config: yoga,    name: "Morning Yoga" },
  { day: 2, hour: 19, type: "hiit",    teacher: teachers[:hiit][0],     config: hiit,    name: "HIIT Blast" },
  { day: 3, hour: 8,  type: "pilates", teacher: teachers[:pilates][0],  config: pilates, name: "Pilates Core" },
  { day: 3, hour: 12, type: "yoga",    teacher: teachers[:yoga][1],     config: yoga,    name: "Morning Yoga" },
  { day: 3, hour: 18, type: "hiit",    teacher: teachers[:hiit][1],     config: hiit,    name: "HIIT Blast" },
  { day: 4, hour: 7,  type: "yoga",    teacher: teachers[:yoga][0],     config: yoga,    name: "Morning Yoga" },
  { day: 4, hour: 10, type: "hiit",    teacher: teachers[:hiit][0],     config: hiit,    name: "HIIT Blast" },
  { day: 5, hour: 9,  type: "yoga",    teacher: teachers[:yoga][1],     config: yoga,    name: "Morning Yoga" },
  { day: 5, hour: 11, type: "pilates", teacher: teachers[:pilates][0],  config: pilates, name: "Pilates Core" },
  { day: 5, hour: 17, type: "hiit",    teacher: teachers[:hiit][1],     config: hiit,    name: "HIIT Blast" },
  { day: 6, hour: 8,  type: "yoga",    teacher: teachers[:yoga][0],     config: yoga,    name: "Morning Yoga" },
  { day: 6, hour: 10, type: "pilates", teacher: teachers[:pilates][0],  config: pilates, name: "Pilates Core" }
].each do |c|
  desc = case c[:type]
         when "yoga"    then yoga_desc
         when "hiit"    then hiit_desc
         when "pilates" then pilates_desc
         end
  capacity = c[:type] == "hiit" ? 15 : 20

  StudioClass.create!(
    studio:           studio,
    class_config:     c[:config],
    name:             c[:name],
    teacher_name:     c[:teacher],
    description:      desc,
    class_type:       c[:type],
    scheduled_at:     Date.today.advance(days: c[:day]).change(hour: c[:hour], min: 0),
    duration_minutes: c[:type] == "hiit" ? 45 : 60,
    capacity:         capacity,
    spots_taken:      rand(0..capacity - 2)
  )
end

puts "Creating deals..."

deal1 = Deal.create!(
  studio: studio,
  name: "First Visit Free",
  deal_type: "discount",
  discount_percent: 100,
  trigger_condition: "first_visit",
  usage_limit: 1,
  expiry_days: 30,
  active: true
)

deal2 = Deal.create!(
  studio: studio,
  name: "10% Off Next Class",
  deal_type: "discount",
  discount_percent: 10,
  trigger_condition: "5th_visit",
  usage_limit: 1,
  expiry_days: 14,
  active: true
)

puts "Creating rewards..."

free_class_reward = Reward.create!(
  studio: studio,
  name: "Free Class",
  reward_type: :free_class,
  points_cost: 0,
  image_url: "https://example.com/free-class.png",
  description: "Unlock one free class after 10 visits.",
  active: true
)

Reward.create!(
  studio: studio,
  name: "Guest Pass",
  reward_type: :free_class,
  points_cost: 0,
  image_url: "https://example.com/guest-pass.png",
  description: "Bring a friend for free — one guest pass on us.",
  active: true
)

Reward.create!(
  studio: studio,
  name: "Merchandise Discount",
  reward_type: :free_class,
  points_cost: 0,
  image_url: "https://example.com/merch.png",
  description: "20% off any item in our studio shop.",
  active: true
)

puts "Creating visits..."

# alice: 10 visits → 1 milestone reached, reward available
configs = [ yoga, hiit, pilates, yoga, hiit, pilates, yoga, hiit, pilates, yoga ]
10.times do |i|
  Visit.create!(
    user: alice,
    studio: studio,
    class_config: configs[i],
    points_earned: configs[i].point_value,
    visited_at: (10 - i).weeks.ago
  )
end

# bob: 9 visits → 9/10 progress
configs9 = [ yoga, hiit, pilates, yoga, hiit, pilates, yoga, hiit, pilates ]
9.times do |i|
  Visit.create!(
    user: bob,
    studio: studio,
    class_config: configs9[i],
    points_earned: configs9[i].point_value,
    visited_at: (9 - i).weeks.ago
  )
end

# carol: 23 visits → 2 milestones reached, 3/10 progress, 1 redemption used → 1 available reward
carol_configs = [ yoga, pilates, hiit, yoga, pilates, yoga, hiit, pilates, yoga, hiit,
                  pilates, yoga, hiit, pilates, yoga, hiit, pilates, yoga, pilates, hiit,
                  yoga, pilates, hiit ]
23.times do |i|
  Visit.create!(
    user: carol,
    studio: studio,
    class_config: carol_configs[i],
    points_earned: carol_configs[i].point_value,
    visited_at: (23 - i).weeks.ago
  )
end

puts "Creating bookings..."

# Link bookings to studio classes where possible
alice_yoga_class  = StudioClass.find_by(studio: studio, class_type: "yoga",
                                         scheduled_at: Date.today.advance(days: 2).change(hour: 7, min: 0))
bob_hiit_class    = StudioClass.find_by(studio: studio, class_type: "hiit",
                                         scheduled_at: Date.today.advance(days: 3).change(hour: 18, min: 0))
carol_hiit_class  = StudioClass.find_by(studio: studio, class_type: "hiit",
                                         scheduled_at: Date.today.advance(days: 4).change(hour: 10, min: 0))

Booking.create!(
  user: alice,
  studio: studio,
  studio_class: alice_yoga_class,
  mindbody_booking_id: 9001,
  class_name: "Morning Yoga",
  class_time: 2.days.from_now.change(hour: 8),
  status: true,
  booked_at: 1.day.ago
)

Booking.create!(
  user: bob,
  studio: studio,
  studio_class: bob_hiit_class,
  mindbody_booking_id: 9002,
  class_name: "HIIT Blast",
  class_time: 3.days.from_now.change(hour: 18),
  status: true,
  booked_at: Time.current
)

Booking.create!(
  user: carol,
  studio: studio,
  mindbody_booking_id: 9003,
  class_name: "Pilates Core",
  class_time: 1.day.from_now.change(hour: 10),
  status: true,
  booked_at: Time.current
)

Booking.create!(
  user: carol,
  studio: studio,
  studio_class: carol_hiit_class,
  mindbody_booking_id: 9004,
  class_name: "HIIT Blast",
  class_time: 5.days.from_now.change(hour: 18),
  status: true,
  booked_at: Time.current
)

puts "Creating deal claims..."

DealClaim.create!(
  user: alice,
  deal: deal1,
  studio: studio,
  code: "FIRST-ALICE-001",
  status: true,
  claimed_at: 10.weeks.ago
)

DealClaim.create!(
  user: bob,
  deal: deal1,
  studio: studio,
  code: "FIRST-BOB-001",
  status: true,
  claimed_at: 9.weeks.ago
)

DealClaim.create!(
  user: carol,
  deal: deal1,
  studio: studio,
  code: "FIRST-CAROL-001",
  status: true,
  claimed_at: 5.weeks.ago
)

DealClaim.create!(
  user: carol,
  deal: deal2,
  studio: studio,
  code: "10OFF-CAROL-001",
  status: true,
  claimed_at: 1.week.ago
)

puts "Creating reward redemptions..."

# No active redemptions for alice so she can test the redeem flow.
# One expired redemption to test the expired state on the show page.
RewardRedemption.create!(
  user: alice,
  reward: free_class_reward,
  studio: studio,
  code: "FREE-EXPIRED01",
  redeemed_at: 45.days.ago,
  expiry_days: 30,
  point_spent: 0,
  status: false
)

# Carol: active redemption she can use at her next class
RewardRedemption.create!(
  user: carol,
  reward: free_class_reward,
  studio: studio,
  code: "FREE-CAROL-001",
  redeemed_at: 3.days.ago,
  expiry_days: 30,
  point_spent: 0,
  status: true
)

puts "Creating chats..."

chat1 = Chat.create!(
  user: alice,
  studio: studio,
  status: true
)

chat2 = Chat.create!(
  user: bob,
  studio: studio,
  status: true
)

puts "Creating messages..."

Message.create!(
  chat: chat1,
  role: "user",
  tag: "inquiry",
  sentiment: "positive",
  content: "Hi! When is the next yoga class?",
  summary: "User asking about yoga schedule"
)

Message.create!(
  chat: chat1,
  role: "assistant",
  tag: "response",
  sentiment: "neutral",
  content: "The next Morning Yoga class is at 8am in 2 days. Would you like to book it?",
  summary: "Assistant provided class schedule"
)

Message.create!(
  chat: chat2,
  role: "user",
  tag: "inquiry",
  sentiment: "positive",
  content: "How many more visits until I get a free class?",
  summary: "User asking about reward progress"
)

Message.create!(
  chat: chat2,
  role: "assistant",
  tag: "response",
  sentiment: "neutral",
  content: "You have 9 visits — just 1 more to unlock your free class!",
  summary: "Assistant shared reward progress"
)

puts "Updating user point totals..."
[ alice, bob, carol ].each(&:recalculate_points!)

puts "Creating notification templates..."
NotificationTemplate::VALID_EVENT_TYPES.each do |event_type|
  title, body = case event_type
  when "reward_unlocked"
    [ "Reward Unlocked!", "Congrats {{first_name}}! You've earned a free class at {{studio_name}}." ]
  when "deal_available"
    [ "New Deal Available", "Hey {{first_name}}, a new deal is waiting for you at {{studio_name}}!" ]
  when "booking_reminder"
    [ "Class Reminder", "Don't forget — {{class_name}} starts in 1 hour at {{studio_name}}." ]
  when "inactive_user"
    [ "We Miss You!", "Hey {{first_name}}, it's been a while. Come back to {{studio_name}} and keep your streak going!" ]
  when "deal_expiry"
    [ "Deal Expiring Soon", "Your deal at {{studio_name}} expires tomorrow — don't miss out!" ]
  end

  NotificationTemplate.create!(
    studio: studio,
    event_type: event_type,
    title_template: title,
    body_template: body,
    enabled: true
  )
end

puts "Creating broadcasts..."
Broadcast.create!(
  studio: studio,
  subject: "Welcome to TAPIN Fitness!",
  body: "Thanks for joining our community. Check in at reception to start earning rewards!",
  channel: "push",
  audience_filter: "all",
  scheduled_at: 1.day.ago,
  sent_at: 1.day.ago,
  total_sent: 3,
  total_delivered: 3,
  total_failed: 0
)

puts "Creating referrals..."
# Alice has an active referral code she can share
Referral.create!(
  referrer: alice,
  status: "pending"
)

# Carol referred Bob (completed)
Referral.create!(
  referrer: carol,
  referred: bob,
  status: "completed",
  completed_at: 8.weeks.ago
)

puts "Creating mock Mindbody clients..."

# Scenario 1: Exact phone match with Alice — auto-links on visit 1
MindbodyClient.create!(
  studio: studio,
  mindbody_client_id: "MB-1001",
  first_name: "Alice",
  last_name: "Martin",
  phone: "611234567",
  email: "alice.martin@gmail.com"
)

# Scenario 2: No phone match for Bob, but name matches — triggers at visit 10
MindbodyClient.create!(
  studio: studio,
  mindbody_client_id: "MB-1002",
  first_name: "Bob",
  last_name: "Chen",
  phone: "699999999",
  email: "bob.chen@gmail.com"
)

# Scenario 3: Client exists in Mindbody but has no TapIn account yet
MindbodyClient.create!(
  studio: studio,
  mindbody_client_id: "MB-1003",
  first_name: "Diana",
  last_name: "Rivera",
  phone: "615551234",
  email: "diana.r@gmail.com"
)

# Scenario 4: Duplicate phone — two Mindbody clients with same number (conflict)
MindbodyClient.create!(
  studio: studio,
  mindbody_client_id: "MB-1004",
  first_name: "Carol",
  last_name: "Park",
  phone: "612345678",
  email: "carol.park@gmail.com"
)

MindbodyClient.create!(
  studio: studio,
  mindbody_client_id: "MB-1005",
  first_name: "Caroline",
  last_name: "Parker",
  phone: "612345678",
  email: "caroline.p@gmail.com"
)

puts "Creating Mindbody links (simulated match results)..."

# Alice: phone matched MB-1001 on visit 1 → auto-linked
MindbodyLink.create!(
  user: alice,
  mindbody_client_id: "MB-1001",
  status: "linked",
  linked_at: 10.weeks.ago,
  match_data: { "matched_by" => "phone", "name" => "Alice Martin" }
)

# Bob: no phone match on visit 1, name match found MB-1002 at visit 9 → pending admin review
MindbodyLink.create!(
  user: bob,
  mindbody_client_id: "MB-1002",
  status: "pending",
  match_data: { "match_type" => "name", "matched_by" => "name", "name" => "Bob Chen" }
)

# Carol: phone matched two Mindbody clients (MB-1004 + MB-1005) → conflict
MindbodyLink.create!(
  user: carol,
  status: "conflict",
  match_data: {
    "conflicting_client_ids" => [ "MB-1004", "MB-1005" ],
    "clients" => [
      { "mindbody_client_id" => "MB-1004", "name" => "Carol Park", "phone" => "612345678" },
      { "mindbody_client_id" => "MB-1005", "name" => "Caroline Parker", "phone" => "612345678" }
    ]
  }
)

# Owner has no Mindbody link (admin, not a customer)

puts "Done! Seed data created successfully."
puts ""
puts "Test scenarios:"
puts "  alice@example.com  — 10 visits, reward available, Mindbody LINKED (MB-1001)"
puts "  bob@example.com    — 9 visits, 1 visit remaining, Mindbody PENDING review (name match MB-1002)"
puts "  carol@example.com  — 23 visits, 1 available reward, Mindbody CONFLICT (MB-1004 vs MB-1005)"
puts ""
puts "Admin Mindbody pages:"
puts "  /admin/mindbody_matches — 1 pending (Bob), 2 recent (Alice linked, Carol conflict)"
puts "  /admin/mindbody_conflicts/#{MindbodyLink.find_by(status: 'conflict')&.id} — Carol's conflict"
