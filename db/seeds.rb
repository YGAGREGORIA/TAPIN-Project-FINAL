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
ClassConfig.destroy_all
Booking.destroy_all
StudioBrand.destroy_all
Studio.destroy_all
User.destroy_all

puts "Creating users..."

alice = User.create!(
  email: "alice@example.com",
  password: "password",
  first_name: "Alice",
  last_name: "Martin",
  phone: 611234567,
  total_points: 320,
  available_points: 150,
  total_visits: 12,
  referred_by: nil,
  last_visit_at: 3.days.ago
)

bob = User.create!(
  email: "bob@example.com",
  password: "password",
  first_name: "Bob",
  last_name: "Chen",
  phone: 619876543,
  total_points: 80,
  available_points: 80,
  total_visits: 4,
  referred_by: "alice@example.com",
  last_visit_at: 1.week.ago
)

owner = User.create!(
  email: "owner@tapinstudio.com",
  password: "password",
  first_name: "Sara",
  last_name: "Lopez",
  phone: 610001111,
  total_points: 0,
  available_points: 0,
  total_visits: 0,
  referred_by: nil,
  last_visit_at: nil
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

reward1 = Reward.create!(
  studio: studio,
  name: "Free Water Bottle",
  points_cost: 100,
  image_url: "https://example.com/water-bottle.png",
  description: "A branded TAPIN water bottle.",
  active: true
)

reward2 = Reward.create!(
  studio: studio,
  name: "One Free Class",
  points_cost: 200,
  image_url: "https://example.com/free-class.png",
  description: "Redeem for any standard class.",
  active: true
)

puts "Creating bookings..."

Booking.create!(
  user: alice,
  studio: studio,
  mindbody_booking_id: 9001,
  class_name: "Morning Yoga",
  class_time: 2.days.from_now.change(hour: 8),
  status: true,
  booked_at: 1.day.ago
)

Booking.create!(
  user: bob,
  studio: studio,
  mindbody_booking_id: 9002,
  class_name: "HIIT Blast",
  class_time: 3.days.from_now.change(hour: 18),
  status: true,
  booked_at: Time.current
)

puts "Creating visits..."

visit1 = Visit.create!(
  user: alice,
  studio: studio,
  class_config: yoga,
  points_earned: 10,
  visited_at: 2.weeks.ago
)

visit2 = Visit.create!(
  user: alice,
  studio: studio,
  class_config: hiit,
  points_earned: 20,
  visited_at: 1.week.ago
)

Visit.create!(
  user: bob,
  studio: studio,
  class_config: pilates,
  points_earned: 15,
  visited_at: 5.days.ago
)

puts "Creating deal claims..."

DealClaim.create!(
  user: alice,
  deal: deal1,
  studio: studio,
  code: "FIRST-ALICE-001",
  status: true,
  claimed_at: 3.weeks.ago
)

DealClaim.create!(
  user: bob,
  deal: deal1,
  studio: studio,
  code: "FIRST-BOB-001",
  status: true,
  claimed_at: 2.weeks.ago
)

puts "Creating reward redemptions..."

RewardRedemption.create!(
  user: alice,
  reward: reward1,
  studio: studio,
  code: "RR-ALICE-001",
  point_spent: 100,
  status: true,
  redeemed_at: 1.week.ago,
  expiry_days: 30
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
  content: "How many points do I have?",
  summary: "User asking about points balance"
)

Message.create!(
  chat: chat2,
  role: "assistant",
  tag: "response",
  sentiment: "neutral",
  content: "You currently have 80 points. Keep going — you're close to a free reward!",
  summary: "Assistant shared points balance"
)

puts "Done! Seed data created successfully."
