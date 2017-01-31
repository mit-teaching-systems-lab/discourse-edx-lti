# ---------------------------------------------------------------
# name:  discourse-omniauth-lti
# about: Discourse as an LTI Provider
# version: 0.0.1
# author: MIT Teaching Systems Lab
# url: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
# ---------------------------------------------------------------


# Plugins need to explicitly include dependencies, and the loading
# mechanism is different than with bundler.
# See https://github.com/discourse/discourse/blob/master/lib/plugin_gem.rb
gem 'ims-lti', '1.1.13', require: false, require_name: 'ims/lti'


# Enable site settings in admin UI.
# We can't put the EdX URL in SiteSetting since it needs to be available at plugin
# registry time.
enabled_site_setting :lti_consumer_key
enabled_site_setting :lti_consumer_secret
LTI_PROVIDER_AUTHENTICATE_URL = 'https://courses.edx.org/courses/course-v1:MITx+11.155x+1T2017/courseware/f26377b4dba34b75ad4e9183361bdcc8/469a0a53e0cd45a1ae3541d7cc5a1d6a/'


# Register Discourse AuthProvider
require_relative 'strategy.rb'
require_relative 'authenticator.rb'
auth_provider title: 'Click to login with EdX',
  authenticator: LTIAuthenticator.new,
  full_screen_login: true,
  custom_url: LTI_PROVIDER_AUTHENTICATE_URL



# Discourse ships with zocial http://zocial.smcllns.com/sample.html
# In our case we don't have an icon for GitLab.
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


# work left
# - site settings? YES
# - redirect from login to EdX?
# - handle LTI post from EdX? YES
# - set the appropriate user and session data for Discourse? YES
# - add guard to redirect everything else to edx, except for admin login?
# - factor out config for EdX url, etc?