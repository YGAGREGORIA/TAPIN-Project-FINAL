class ApplicationController < ActionController::Base
  allow_browser versions: { safari: 16, chrome: 109, firefox: 121, opera: 104, ie: false }

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
