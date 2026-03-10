class Visit < ApplicationRecord
  belongs_to :user
  belongs_to :studio
  belongs_to :class_config
end
