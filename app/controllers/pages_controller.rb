class PagesController < ApplicationController
  def home
    @studios = Studio.where(active: true).includes(:studio_brand).order(:name)
  end
end
