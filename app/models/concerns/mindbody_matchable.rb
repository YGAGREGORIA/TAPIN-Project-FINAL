module MindbodyMatchable
  extend ActiveSupport::Concern

  included do
    after_create :enqueue_mindbody_match
  end

  private

  def enqueue_mindbody_match
    visit_count = user.visits.where(studio: studio).count

    case visit_count
    when 1
      MindbodyMatchJob.perform_later(user.id, studio.id, "phone")
    when 10
      MindbodyMatchJob.perform_later(user.id, studio.id, "name")
    end
  end
end
