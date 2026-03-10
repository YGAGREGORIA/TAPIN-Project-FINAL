class CreateStudioBrands < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_brands do |t|
      t.references :studio, null: false, foreign_key: true
      t.string :primary_color
      t.string :secondary_color
      t.string :background_color
      t.string :text_color
      t.string :logo_url
      t.string :font_heading
      t.string :font_body
      t.string :brand_tone
      t.string :tagline
      t.string :raw_extraction

      t.timestamps
    end
  end
end
