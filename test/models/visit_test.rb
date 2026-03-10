require "test_helper"

class VisitTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email: "owner@visit-test.com", password: "password")
    @studio = Studio.create!(
      user: @owner,
      name: "Visit Test Studio",
      slug: "visit-test-studio",
      active: true
    )
    @user = User.create!(email: "subject@visit-test.com", password: "password")
    @class_config = ClassConfig.create!(
      studio: @studio,
      mindbody_class_id: 901,
      class_name: "Visit Test Class",
      point_value: 10,
      is_premium: false
    )
  end

  def build_visit(visited_at:)
    Visit.new(
      user: @user,
      studio: @studio,
      class_config: @class_config,
      visited_at: visited_at,
      points_earned: 10
    )
  end

  def create_visit(visited_at:)
    build_visit(visited_at: visited_at).tap(&:save!)
  end

  # --- 12-hour deduplication ---

  test "first visit is always valid" do
    assert build_visit(visited_at: Time.current).valid?
  end

  test "second visit within 12 hours does not count" do
    create_visit(visited_at: 6.hours.ago)
    visit = build_visit(visited_at: Time.current)
    assert_not visit.valid?
    assert_includes visit.errors[:base],
      "This visit was not counted. You need to wait at least 12 hours before tapping in again."
  end

  test "second visit at exactly 12 hours counts" do
    create_visit(visited_at: 12.hours.ago)
    assert build_visit(visited_at: Time.current).valid?
  end

  test "second visit after more than 12 hours counts" do
    create_visit(visited_at: 13.hours.ago)
    assert build_visit(visited_at: Time.current).valid?
  end

  # --- 12-hour rule is scoped to the studio ---

  test "visit at a different studio does not trigger the 12-hour wait" do
    other_studio = Studio.create!(
      user: @owner,
      name: "Other Studio",
      slug: "other-studio",
      active: true
    )
    other_config = ClassConfig.create!(
      studio: other_studio,
      mindbody_class_id: 902,
      class_name: "Other Class",
      point_value: 10,
      is_premium: false
    )

    Visit.create!(
      user: @user,
      studio: other_studio,
      class_config: other_config,
      visited_at: 1.hour.ago,
      points_earned: 10
    )

    assert build_visit(visited_at: Time.current).valid?
  end

  # --- saved visits contribute to reward count ---

  test "9 saved visits do not reach a reward milestone" do
    9.times do |i|
      create_visit(visited_at: ((9 - i) * 2).days.ago)
    end
    assert_equal 0, @user.reward_milestones_reached_for(@studio)
  end

  test "10 saved visits reach exactly one reward milestone" do
    10.times do |i|
      create_visit(visited_at: ((10 - i) * 2).days.ago)
    end
    assert_equal 1, @user.reward_milestones_reached_for(@studio)
  end

  test "a rejected visit does not increment the visit count" do
    create_visit(visited_at: 6.hours.ago)
    rejected = build_visit(visited_at: Time.current)
    rejected.save
    assert_not rejected.persisted?
    assert_equal 1, @user.visits_count_for(@studio)
  end
end
