# Discourse Authenticator class
class LTIAuthenticator < ::Auth::Authenticator  
  # override hook
  def name
    'lti'
  end

  # override hook
  def register_middleware(omniauth)
    log :info, 'register_middleware'
    omniauth.provider :lti
  end

  # override hook
  # The UX we want here is that if this is the first time a learner has authenticated,
  # we'll create a new user record for them automatically (so they don't see the modal
  # for creating their own user).  A second-time learner should just be authenticated
  # and go right into Discourse.
  #
  # We've set `SiteSetting.invite_only?` to true in order to disable the "Sign up" flow
  # in Discourse.  So this code instantiates a new User record because otherwise the
  # standard flow will popup a dialog to let them change their username, and that would
  # fail to create a new user since `SiteSetting.invite_only?` is true.
  def after_authenticate(auth_token)
    log :info, 'after_authenticate'
    log :info, "after_authenticate, auth_token: #{auth_token.inspect}"
    auth_result = Auth::Result.new

    # Grab the info we need from OmniAuth
    omniauth_params = auth_token[:info]
    auth_result.username = omniauth_params[:edx_username]
    auth_result.email = omniauth_params[:email]
    auth_result.email_valid = auth_result.email.present?
    auth_result.name = auth_result.username
    lti_uid = auth_token[:uid]
    auth_result.extra_data = omniauth_params.merge(lti_uid: lti_uid)
    log :info, "after_authenticate, auth_result: #{auth_result.inspect}"

    # Lookup or instantiate a User record and set a reference to it.  This is required as part of the
    # implementation of `omniauth_callback_controller#complete_response_data`.  That method will then
    # mark the User as active and save it to the database.
    #
    # There seems like there should be a better way to do this, but I haven't found it yet.
    auth_result.user = User.find_or_initialize_by({
      email: auth_result.email,
      username: auth_result.username
    })
    log :info, "after_authenticate, user: #{auth_result.user.inspect}"
    
    # This isn't needed for authentication, it just tracks the unique EdX user ids
    # in a way we could look them up from the EdX username if we needed to.
    # We only do this once.
    plugin_store_key = "lti_username_#{auth_result.username}"
    user_info = ::PluginStore.get('lti', plugin_store_key)
    if not user_info
      log :info, "after_authenticate, PluginStore.set for auth_result: #{auth_result.inspect}"
      ::PluginStore.set('lti', plugin_store_key, auth_result.as_json)
    end

    auth_result
  end

  protected
  def log(method_symbol, text)
    Rails.logger.send(method_symbol, "LTIAuthenticator: #{text}")
  end  
end