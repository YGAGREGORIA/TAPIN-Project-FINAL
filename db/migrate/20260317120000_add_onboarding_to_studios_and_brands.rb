class AddOnboardingToStudiosAndBrands < ActiveRecord::Migration[8.1]
  def change
    # Tracks which onboarding step the admin has reached.
    # 0 = not started, 1 = step 1 done, 2 = step 2 done, 3 = complete (step 3 done or skipped)
    add_column :studios, :onboarding_step, :integer, default: 0, null: false

    add_column :studio_brands, :instagram_url, :string
    add_column :studio_brands, :facebook_url, :string
    add_column :studio_brands, :website_url, :string
    add_column :studio_brands, :philosophy, :text
    # PostgreSQL native text[] array — no serialisation needed in Rails
    add_column :studio_brands, :vibe_keywords, :string, array: true, default: []
  end
end
