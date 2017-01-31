class LtiController < ApplicationController
  skip_before_filter :redirect_to_login_if_required
  skip_before_filter :preload_json

  def redirect_to_consumer
    url = SiteSetting.lti_consumer_authenticate_url
    Rails.logger :info, "LtiController: redirecting to #{url}..."
    redirect url
  end
end