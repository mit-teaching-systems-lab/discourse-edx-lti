# Discourse Authenticator class
class LTIAuthenticator < ::Auth::Authenticator  
  def name
    'lti'
  end

  def register_middleware(omniauth)
    Rails.logger.info 'KR: register_middleware'
    omniauth.provider(:lti, {
      consumer_key: SiteSetting.lti_consumer_key,
      consumer_secret: SiteSetting.lti_consumer_secret
    })
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