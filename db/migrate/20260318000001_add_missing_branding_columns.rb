class AddMissingBrandingColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :studio_brands, :facebook_url, :string
    add_column :studio_brands, :instagram_url, :string
    add_column :studio_brands, :philosophy, :text
    add_column :studio_brands, :vibe_keywords, :string, array: true, default: []
    add_column :studio_brands, :website_url, :string
  end
end
