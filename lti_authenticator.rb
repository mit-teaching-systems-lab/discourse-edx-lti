# Discourse Authenticator class
class LTIAuthenticator < ::Auth::Authenticator  
  DISCOURSE_USERNAME_MAX_LENGTH = 20

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
    # Discourse has a limit of 20 characters for usernames, but EdX does not.
    omniauth_params = auth_token[:info]
    auth_result.username = build_discourse_username omniauth_params[:edx_username]
    auth_result.name = omniauth_params[:edx_username]
    auth_result.email = omniauth_params[:email]
    auth_result.email_valid = auth_result.email.present?
    lti_uid = auth_token[:uid]
    auth_result.extra_data = omniauth_params.merge(lti_uid: lti_uid)
    log :info, "after_authenticate, auth_result: #{auth_result.inspect}"

    # Lookup or create a new User record, requiring that both email and username match.
    # Discourse's User model patches some Rails methods, so we use their
    # methods here rather than reaching into details of how these fields are stored in the DB.
    # This appears related to changes in https://github.com/discourse/discourse/pull/4977
    user_by_email = User.find_by_email(auth_result.email.downcase)
    user_by_username = User.find_by_username(auth_result.username)
    both_matches_found = user_by_email.present? && user_by_username.present?
    no_matches_found = user_by_email.nil? && user_by_username.nil?
    if both_matches_found && user_by_email.id == user_by_username.id
      log :info, "after_authenticate, found user records by both username and email and they matched, using existing user..."
      user = user_by_email
    elsif no_matches_found
      log :info, "after_authenticate, no matches found for email or username, creating user record for first-time user..."
      user = User.new(email: auth_result.email.downcase, username: auth_result.username)
      user.staged = false
      user.active = true
      user.password = SecureRandom.hex(32)
      user.save!
      user.reload
    else
      log :info, "after_authenticate, found user records that did not match by username and email"
      log :info, "after_authenticate, user_by_email: #{user_by_email.inspect}"
      log :info, "after_authenticate, user_by_username: #{user_by_username.inspect}"
      raise ::ActiveRecord::RecordInvalid('LTIAuthenticator: edge case for finding User records where username and email did not match, aborting...')
    end

    # Return a reference to the User record.
    auth_result.user = user
    log :info, "after_authenticate, user: #{auth_result.user.inspect}"
    
    # This isn't needed for authentication, it just tracks the unique EdX user ids
    # in a way we could look them up from the EdX username if we needed to.
    plugin_store_key = "lti_username_#{auth_result.username}"
    ::PluginStore.set('lti', plugin_store_key, auth_result.as_json)
    log :info, "after_authenticate, PluginStore.set for auth_result: #{auth_result.as_json}"

    auth_result
  end

  protected
  def log(method_symbol, text)
    Rails.logger.send(method_symbol, "LTIAuthenticator: #{text}")
  end

  # Discourse has a limit of 20 characters for usernames, but EdX does not, so we slice it.
  # Edx username can still be (or become) invalid after the slicing.
  # E.g. it can end on special symbol(.-_) or contain more than 1 underscore in a row
  def build_discourse_username(edx_username)
    edx_username.slice(0, DISCOURSE_USERNAME_MAX_LENGTH).gsub("__","_").chomp("_")
  end
end