class LtiController < ApplicationController
  def redirect_to_consumer
    url = SiteSetting.lti_consumer_authenticate_url
    Rails.logger :info, "LtiController: redirecting to #{url}..."
    redirect url
  end
end