class MindbodyMatchJob < ApplicationJob
  queue_as :default

  def perform(user_id, studio_id, match_type)
    user = User.find(user_id)
    studio = Studio.find(studio_id)

    # Skip if already linked at this studio
    return if user.mindbody_links.exists?(status: "linked")

    case match_type
    when "phone"
      match_by_phone(user, studio)
    when "name"
      match_by_name(user, studio)
    end
  end

  private

  def match_by_phone(user, studio)
    phone = user.phone.to_s
    return if phone.blank?

    matches = studio.mindbody_clients.by_phone(phone)

    case matches.count
    when 0
      # No match — user stays standalone, name match will try at visit 10
      find_or_create_link(user, status: "standalone")
    when 1
      # Single match — auto-link
      client = matches.first
      link = find_or_create_link(user, status: "pending")
      link.link!(client.mindbody_client_id)
    else
      # Multiple matches — conflict, admin must resolve
      link = find_or_create_link(user, status: "conflict")
      link.update!(match_data: matches.map { |c|
        { mindbody_client_id: c.mindbody_client_id, name: "#{c.first_name} #{c.last_name}", phone: c.phone }
      })
    end
  end

  def match_by_name(user, studio)
    return if user.first_name.blank? || user.last_name.blank?

    # Only try name match for users not yet linked
    existing = user.mindbody_links.first
    return if existing&.status == "linked"

    matches = studio.mindbody_clients.by_name(user.first_name, user.last_name)

    case matches.count
    when 0
      # Still no match
      nil
    when 1
      # Single name match — pending until admin confirms
      client = matches.first
      link = find_or_create_link(user, status: "pending")
      link.update!(
        mindbody_client_id: client.mindbody_client_id,
        match_data: { matched_by: "name", name: "#{client.first_name} #{client.last_name}" }
      )
    else
      # Multiple name matches — conflict
      link = find_or_create_link(user, status: "conflict")
      link.update!(match_data: matches.map { |c|
        { mindbody_client_id: c.mindbody_client_id, name: "#{c.first_name} #{c.last_name}" }
      })
    end
  end

  def find_or_create_link(user, status:)
    link = user.mindbody_links.first
    if link
      link.update!(status: status) unless link.status == "linked"
      link
    else
      user.mindbody_links.create!(status: status)
    end
  end
end
