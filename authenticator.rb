# Discourse Authenticator class
class LTIAuthenticator < ::Auth::Authenticator  
  def name
    'lti'
  end

  def register_middleware(omniauth)
    Rails.logger.info 'KR: register_middleware'
    omniauth.provider :lti
  end

  def after_authenticate(auth_token)
    Rails.logger.info 'KR: after_authenticate'
    Rails.logger.info "KR: after_authenticate, auth_token: #{auth_token.inspect}"
    result = Auth::Result.new

    # Grap the info we need from OmniAuth
    omniauth_params = auth_token[:info]
    result.username = omniauth_params[:edx_username]
    result.email = omniauth_params[:email]
    result.email_valid = result.email.present?
    result.name = result.username
    lti_uid = auth_token[:uid]
    result.extra_data = omniauth_params.merge(lti_uid: lti_uid)
    
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
    Rails.logger.info "KR: after_create_account, auth: #{auth.inspect}"
    Rails.logger.info "KR: after_create_account, user: #{user.inspect}"
    
    lti_uid = auth[:extra_data][:lti_ud]
    email = auth[:extra_data][:email]
    ::PluginStore.set('lti', "lti_uid_#{lti_uid}", { email: email })
    true
  end   
end