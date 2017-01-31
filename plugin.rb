# ---------------------------------------------------------------
# name:  discourse-omniauth-lti
# about: Discourse plugin to authenticate with LTI (eg., for an EdX course)
# version: 0.0.1
# author: MIT Teaching Systems Lab
# url: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
# ---------------------------------------------------------------


# Plugins need to explicitly include their dependencies, and the loading
# mechanism is different than with bundler.
# See https://github.com/discourse/discourse/blob/master/lib/plugin_gem.rb
gem 'ims-lti', '1.1.13', require: false, require_name: 'ims/lti'


# Enable site settings in admin UI.
# We can't put the EdX URL in SiteSetting since it needs to be available at plugin
# registry time.
enabled_site_setting :lti_consumer_key
enabled_site_setting :lti_consumer_secret
enabled_site_setting :lti_consumer_authenticate_url


# Add an endpoint that will redirect to the EdX URL
# This is a separate endpoint so that we can respond to changes in a `SiteSetting`
# as soon as an admin user changes them in the UI.  If we passed in the `custom_url`
# value into the auth_provider at boot time, we'd need to restart the server to pick
# up the new value.
REDIRECT_TO_CONSUMER_ROUTE = '/lti/redirect_to_consumer'
Rails.application.routes.draw do 
  get REDIRECT_TO_CONSUMER_ROUTE => 'lti#redirect_to_consumer'
end


# Register Discourse AuthProvider
require_relative 'strategy.rb'
require_relative 'authenticator.rb'
auth_provider({
  title: 'Login with EdX',
  message: 'Click to login with EdX',
  authenticator: LTIAuthenticator.new,
  full_screen_login: true,
  custom_url: REDIRECT_TO_CONSUMER_ROUTE
})



# This styles the login button
register_css <<CSS

.btn-social.lti {
  height: 38px;
  font-size: 16px;
  margin-bottom: 20px !important;
  text-align: left;
  color: white;
  background-color: rgb(183, 38, 103);
  background-size: 32px;
  background-repeat: no-repeat;
  background-position-x: 10px;
}

CSS
