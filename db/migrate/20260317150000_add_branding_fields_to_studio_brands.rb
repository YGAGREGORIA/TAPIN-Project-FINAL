class AddBrandingFieldsToStudioBrands < ActiveRecord::Migration[8.1]
  def up
    # Upgrade raw_extraction from string to text so it can store 3 AI proposals as JSON
    change_column :studio_brands, :raw_extraction, :text
  end

  def down
    change_column :studio_brands, :raw_extraction, :string
  end
end
