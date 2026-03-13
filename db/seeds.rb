# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Cleaning database..."
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
  password: "Password123",
  confirmed_at: Time.current,
  first_name: "Alice",
  last_name: "Martin",
  admin: true,
  phone: 611234567,
  referred_by: nil,
  last_visit_at: 1.day.ago
)

# bob: 9 visits → almost there (9/10)
bob = User.create!(
  email: "bob@example.com",
  password: "Password123",
  confirmed_at: Time.current,
  first_name: "Bob",
  last_name: "Chen",
  phone: 619876543,
  referred_by: "alice@example.com",
  last_visit_at: 2.days.ago
)

# carol: 20 visits → 2 milestones, 1 redemption used, 1 available reward, 2 deals claimed, 2 upcoming bookings
carol = User.create!(
  email: "carol@example.com",
  password: "Password123",
  confirmed_at: Time.current,
  first_name: "Carol",
  last_name: "Park",
  phone: 612345678,
  referred_by: nil,
  last_visit_at: 1.week.ago
)

owner = User.create!(
  email: "owner@tapinstudio.com",
  password: "Password123",
  confirmed_at: Time.current,
  first_name: "Sara",
  last_name: "Lopez",
  phone: 610001111,
  referred_by: nil,
  last_visit_at: nil
)

puts "Creating studios..."

studio = Studio.create!(
  user: alice,
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
  name: "Refer a Friend — 10% Off",
  deal_type: "discount",
  discount_percent: 10,
  trigger_condition: "referral",
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
  active: true,
  claimed_at: 10.weeks.ago
)

DealClaim.create!(
  user: bob,
  deal: deal1,
  studio: studio,
  code: "FIRST-BOB-001",
  active: true,
  claimed_at: 9.weeks.ago
)

DealClaim.create!(
  user: carol,
  deal: deal1,
  studio: studio,
  code: "FIRST-CAROL-001",
  active: true,
  claimed_at: 5.weeks.ago
)

DealClaim.create!(
  user: carol,
  deal: deal2,
  studio: studio,
  code: "10OFF-CAROL-001",
  active: true,
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

puts "Done! Seed data created successfully."
puts ""
puts "Login credentials:"
puts "  Password for all seeded users: Password123"
puts "  Sign in at: http://localhost:3000/users/sign_in"
puts ""
puts "Test scenarios:"
puts "  alice@example.com  — admin, 10 visits, reward available (+ 1 expired redemption)"
puts "  bob@example.com    — 9 visits, 1 visit remaining"
puts "  carol@example.com  — 20 visits, 1 available reward, 2 upcoming bookings, 2 deal claims, active reward redemption"
puts "  owner@tapinstudio.com — studio owner account"
