class AddMissingBrandingColumns < ActiveRecord::Migration[8.1]
  def change
    add_column :studio_brands, :facebook_url, :string unless column_exists?(:studio_brands, :facebook_url)
    add_column :studio_brands, :instagram_url, :string unless column_exists?(:studio_brands, :instagram_url)
    add_column :studio_brands, :philosophy, :text unless column_exists?(:studio_brands, :philosophy)
    add_column :studio_brands, :vibe_keywords, :string, array: true, default: [] unless column_exists?(:studio_brands, :vibe_keywords)
    add_column :studio_brands, :website_url, :string unless column_exists?(:studio_brands, :website_url)
  end
end
