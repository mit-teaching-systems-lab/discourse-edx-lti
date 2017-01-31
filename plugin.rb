# name:  discourse-omniauth-lti
# about: Discourse as an LTI Provider
# version: 0.0.1
# author: MIT Teaching Systems Lab
# url: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
gem 'ims-lti', '1.1.13', require: false, require_name: 'ims/lti'
gem 'omniauth-lti', '0.0.2'


# enable these site settings
enabled_site_setting :lti_consumer_key
enabled_site_setting :lti_consumer_secret
enabled_site_setting :lti_provider_authenticate_url

class LTIAuthenticator < ::Auth::Authenticator  
  def name
    'lti'
  end

  def register_middleware(omniauth)
    Rails.logger.info 'KR: register_middleware'
    oauth_credentials = {
      SiteSetting.lti_consumer_key => SiteSetting.lti_consumer_secret
    }
    omniauth.provider :lti, { :oauth_credentials => oauth_credentials }
  end

  def after_authenticate(auth_token)
    Rails.logger.info 'KR: after_authenticate'
    result = Auth::Result.new

    # Grap the info we need from OmniAuth
    data = auth_token[:info]
    result.email = data['email']
    result.email_valid = result.email.present?
    result.username = data['first_name'] + ' ' + data['last_name']
    result.name = result.username
    lti_uid = auth_token['uid']
    result.extra_data = data.merge(lti_uid: lti_uid)
    
    # Check if the user is an existing account and add them to the PluginStore if not
    # This isn't needed for authentication, just tracking
    user_info = ::PluginStore.get('lti', "lti_uid_#{lti_uid}")
    unless user_info
      ::PluginStore.set('lti', "lti_uid_#{lti_uid}", { email: result.email })
    end
    result
  end

  def after_create_account(user, auth)
    Rails.logger.info 'KR: after_create_account'
    lti_uid = auth[:extra_data]['lti_uid']
    email = auth[:extra_data]['email']
    ::PluginStore.set('lti', "lti_uid_#{lti_uid}", { email: email })
    true
  end   
end

auth_provider title: 'LTI',
  message: 'Log in via LTI',
  authenticator: LTIAuthenticator.new,
  custom_url: 'https://courses.edx.org/courses/course-v1:MITx+11.155x+1T2017/courseware/f26377b4dba34b75ad4e9183361bdcc8/469a0a53e0cd45a1ae3541d7cc5a1d6a/' || SiteSetting.lti_provider_authenticate_url





# work left
# - site settings? YES
# - redirect from login to EdX?
# - handle LTI post from EdX?
# - set the appropriate user and session data for Discourse?
# - add guard to redirect everything else to edx, except for admin login?
# - config for EdX url, etc?


# Plugins need to explicitly include dependencies, and the loading
# mechanism is different than bundler's.
#
# See https://meta.discourse.org/t/plugin-installation-issue-with-omniauth-ldap/30090/4
# Relevant Discourse source https://github.com/discourse/discourse/blob/master/lib/plugin_gem.rb
