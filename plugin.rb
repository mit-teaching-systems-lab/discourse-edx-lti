# name:  discourse-omniauth-lti
# about: Discourse as an LTI Provider
# version: 0.0.1
# author: MIT Teaching Systems Lab
# url: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
gem 'omniauth-lti', '0.0.2'
gem 'ims-lti'


# enable these site settings
enabled_site_setting :lti_consumer_key
enabled_site_setting :lti_consumer_secret

class LTIAuthenticator < ::Auth::Authenticator  
  def name
    'lti'
  end

  def register_middleware(omniauth)
    oauth_credentials = {
      SiteSetting.lti_consumer_key => SiteSetting.lti_consumer_secret
    }
    omniauth.provider :lti, { :oauth_credentials => oauth_credentials }
  end

  def after_authenticate(auth_token)
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
    lti_uid = auth[:extra_data]['lti_uid']
    email = auth[:extra_data]['email']
    ::PluginStore.set('lti', "lti_uid_#{lti_uid}", { email: email })
    true
  end   
end

auth_provider title: 'LTI',
  message: 'Log in via LTI',
  authenticator: LTIAuthenticator.new


# have to point back to the EdX URL
# also unclear if we need to add an endpoint to accept this
# and unclear on the mental model of LTI and the model of OmniAuth and Discourse
# Authenticator plugins
# not sure about mixin, initializer either.
