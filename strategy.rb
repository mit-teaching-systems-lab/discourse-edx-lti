# enabled_site_setting :lti_provider_url

# # Redirect the user to an LTI provider (eg., EdX).  They'll authenticate there,
# # and then 
# # based on https://github.com/omniauth/omniauth/wiki/strategy-contribution-guide
# class LTIStrategy
#   def request_phase
#     redirect_uri = '/auth/lti/callback' # TODO(kr)
#     redirect client.auth_code.authorize_url({redirect_uri: redirect_uri}.merge(options.authorize_params))
#   end

#   def callback_phase
#   end
# end