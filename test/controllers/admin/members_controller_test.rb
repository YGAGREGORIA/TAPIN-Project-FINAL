require "test_helper"

class Admin::MembersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @owner = User.create!(
      email: "owner@admin-members.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: true,
      role: 1  # non-customer role so owner does not appear in the members list
    )
    @studio = Studio.create!(
      user: @owner,
      name: "Members Test Studio",
      slug: "members-test-studio",
      active: true
    )
    @member = User.create!(
      email: "member@admin-members.com",
      password: "Password123",
      confirmed_at: Time.current,
      first_name: "Jane",
      last_name: "Doe",
      role: 0
    )
  end

  # ── auth ─────────────────────────────────────────────────────────

  test "redirects unauthenticated user from index" do
    get admin_members_path
    assert_redirected_to new_user_session_path
  end

  test "redirects unauthenticated user from show" do
    get admin_member_path(@member)
    assert_redirected_to new_user_session_path
  end

  test "blocks unauthenticated user from export" do
    get export_admin_members_path(format: :csv)
    # Devise returns 401 for non-HTML formats when unauthenticated
    assert_includes [ 401, 302 ], response.status
  end

  test "redirects non-admin user to root" do
    non_admin = User.create!(
      email: "nonadmin@admin-members.com",
      password: "Password123",
      confirmed_at: Time.current,
      admin: false
    )
    sign_in non_admin
    get admin_members_path
    assert_redirected_to root_path
  end

  # ── index ─────────────────────────────────────────────────────────

  test "admin can access members index" do
    sign_in @owner
    get admin_members_path
    assert_response :success
  end

  test "index lists customer-role members" do
    sign_in @owner
    get admin_members_path
    assert_match @member.email, response.body
  end

  test "index does not list non-customer users" do
    sign_in @owner
    get admin_members_path
    assert_no_match @owner.email, response.body
  end

  test "index shows total member count" do
    expected = User.where(role: 0).count
    sign_in @owner
    get admin_members_path
    assert_match "#{expected} Mitglieder", response.body
  end

  test "index search filters by first name" do
    other_member = User.create!(
      email: "other@admin-members.com",
      password: "Password123",
      confirmed_at: Time.current,
      first_name: "John",
      last_name: "Smith",
      role: 0
    )
    sign_in @owner
    get admin_members_path, params: { q: "Jane" }
    assert_match @member.email, response.body
    assert_no_match other_member.email, response.body
  end

  test "index search filters by email" do
    sign_in @owner
    get admin_members_path, params: { q: "member@admin-members" }
    assert_match @member.email, response.body
  end

  test "index search with no matches shows zero members" do
    sign_in @owner
    get admin_members_path, params: { q: "zzznomatch" }
    assert_match "0 Mitglieder", response.body
  end

  test "index paginates: defaults to page 1" do
    sign_in @owner
    get admin_members_path
    assert_match "Seite 1 von", response.body
  end

  test "index clamps page below 1 to page 1" do
    sign_in @owner
    get admin_members_path, params: { page: 0 }
    assert_match "Seite 1 von", response.body
  end

  test "index respects sort param date-oldest in select" do
    sign_in @owner
    get admin_members_path, params: { sort: "date-oldest" }
    assert_response :success
    assert_match "date-oldest", response.body
  end

  test "index renders successfully with invalid sort param" do
    sign_in @owner
    get admin_members_path, params: { sort: "invalid-sort" }
    assert_response :success
  end

  test "index renders successfully with sort param points-high" do
    sign_in @owner
    get admin_members_path, params: { sort: "points-high" }
    assert_response :success
    assert_match "points-high", response.body
  end

  test "index renders successfully with sort param visits-low" do
    sign_in @owner
    get admin_members_path, params: { sort: "visits-low" }
    assert_response :success
    assert_match "visits-low", response.body
  end

  # ── show ──────────────────────────────────────────────────────────

  test "admin can access member show page" do
    sign_in @owner
    get admin_member_path(@member)
    assert_response :success
  end

  test "show page displays member email" do
    sign_in @owner
    get admin_member_path(@member)
    assert_match @member.email, response.body
  end

  test "show returns 404 for non-existent member" do
    sign_in @owner
    get admin_member_path(id: 0)
    assert_response :not_found
  end

  test "show lists available active rewards for studio" do
    reward = Reward.create!(studio: @studio, name: "Free Class", active: true)
    sign_in @owner
    get admin_member_path(@member)
    assert_match reward.name, response.body
  end

  test "show does not list inactive rewards" do
    active_reward   = Reward.create!(studio: @studio, name: "Active Reward",   active: true)
    inactive_reward = Reward.create!(studio: @studio, name: "Inactive Reward", active: false)
    sign_in @owner
    get admin_member_path(@member)
    assert_match    active_reward.name,   response.body
    assert_no_match inactive_reward.name, response.body
  end

  test "show renders successfully with visits present" do
    class_config = ClassConfig.create!(studio: @studio, class_name: "Yoga", point_value: 1)
    # Create visits in chronological order to satisfy the 12-hour gap validation
    Visit.create!(user: @member, studio: @studio, class_config: class_config, visited_at: 10.days.ago)
    sign_in @owner
    get admin_member_path(@member)
    assert_response :success
  end

  # ── export ────────────────────────────────────────────────────────

  test "export as CSV returns attachment" do
    sign_in @owner
    get export_admin_members_path(format: :csv)
    assert_response :success
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_match "members-", response.headers["Content-Disposition"]
  end

  test "export as HTML redirects to members index" do
    sign_in @owner
    get export_admin_members_path
    assert_redirected_to admin_members_path
  end

  test "export CSV sets correct Content-Disposition filename" do
    sign_in @owner
    get export_admin_members_path(format: :csv)
    assert_match "members-#{Date.today}", response.headers["Content-Disposition"]
  end

  test "export CSV returns 200 success" do
    sign_in @owner
    get export_admin_members_path(format: :csv)
    assert_response :success
  end
end
