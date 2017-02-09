# OmniAuth strategy.  By adding it in this namespace, OmniAuth will load it when
# we ask for the :lti provider.
require 'ims/lti'

# This is from the docs in https://github.com/instructure/ims-lti
require 'oauth/request_proxy/rack_request'

module OmniAuth
  module Strategies
    class Lti
      include OmniAuth::Strategy

      # These are the params that the LTI Tool Provider receives
      # in the LTI handoff.  The values here are set in `callback_phase`.
      uid { @lti_provider.user_id }
      info do
        {
          edx_username: @lti_provider.lis_person_sourcedid,
          email: @lti_provider.lis_person_contact_email_primary,
          roles: @lti_provider.roles,
          resource_link_id: @lti_provider.resource_link_id,
          context_id: @lti_provider.context_id
        }
      end
      extra do
        { :raw_info => @lti_provider.to_params }
      end

      def callback_phase
        # Rescue more generic OAuth errors and scenarios
        begin
          log :info, 'callback_phase: start'
          @lti_provider = create_valid_lti_provider!(request)

          log :info, "lti_provider.custom_params: #{@lti_provider.custom_params.inspect}"
          set_origin_url!(@lti_provider.custom_params)
          super
        rescue ::ActionController::BadRequest
          return [400, {}, ['400 Bad Request']]
        rescue ::Timeout::Error
          fail!(:timeout)
        rescue ::Net::HTTPFatalError, ::OpenSSL::SSL::SSLError
          fail!(:service_unavailable)
        rescue ::OAuth::Unauthorized
          fail!(:invalid_credentials)
        rescue ::OmniAuth::NoSessionError
          fail!(:session_expired)
        end
      end

      protected
      def log(method_symbol, text)
        Rails.logger.send(method_symbol, "LTIStrategy: #{text}")
      end

      # Creates and LTI provider and validates the request, returning
      # an IMS LTI ToolProvider.  Raises ActionController::BadRequest if it fails.
      def create_valid_lti_provider!(request)
        if request.request_method != 'POST'
          log :info, "Request method unsupported: #{request.request_method}"
          raise ActionController::BadRequest.new('Unsupported method')
        end

        # Check that consumer key is what we expect
        credentials = read_credentials()
        request_consumer_key = request.params['oauth_consumer_key']
        log :info, "Checking LTI params for consumer_key #{credentials[:consumer_key]}: #{request.params}"
        if request_consumer_key != credentials[:consumer_key]
          log :info, 'Invalid consumer key'
          raise ActionController::BadRequest.new('Invalid request')
        end

        # Create provider and validate request
        lti_provider = IMS::LTI::ToolProvider.new(credentials[:consumer_key], credentials[:consumer_secret], request.params)
        if not lti_provider.valid_request?(request)
          log :info, 'lti_provider.valid_request? failed'
          raise ActionController::BadRequest.new('Invalid LTI request')
        end

        lti_provider
      end

      # This uses Discourse's SiteSetting for configuration, which can be changed
      # through the admin UI.  Using OmniAuth's nice declarative syntax for credential options
      # means those values need to be passed in at app startup time, and changes in the admin
      # UI don't have an effect until restarting the server.
      def read_credentials
        {
          consumer_key: SiteSetting.lti_consumer_key,
          consumer_secret: SiteSetting.lti_consumer_secret
        }
      end

      # Respect the "url" custom parameter in EdX and make sure we redirect to it
      # after authentication.  This allows learners to click an LTI link and jump
      # directly to a particular page.
      # 
      # Typical OmniAuth strategies expect all URLs to redirect to a login
      # page, and then thread the origin URL through the OAuth process as the
      # `origin` query param.  LTI expects to be able to post to a single URL, and
      # pass params about where to navigate to afterward.  If we passed the `origin`
      # query param, this would work with OmniAuth and Discourse to a certain point,
      # but the EdX Studio UI requires query string params to be properly escaped,
      # which is a barrier for course authors.  So we work around by having authors
      # set `["url=https://foo.com/whatever"]` in EdX studio, and read that here.
      #
      # Unfortunately, Discourse checks `omniauth.origin` but overrides whatever it finds
      # there if a :destination_url cookie is set (see omniauth_callbacks#complete), and
      # in the LTI path it will be set to the root URL.  So here we set that cookie directly,
      # which Discourse reads in the controller and redirects to after finishing the
      # authentication process.
      #
      # Since the request is LTI-signed, this is secure, but Discourse will
      # parse it and discard the domain to be safe.
      def set_origin_url!(lti_custom_params)
        origin_url = lti_custom_params['url']
        return unless origin_url

        log :info, "set_origin_url: #{origin_url}"
        @env['action_dispatch.cookies'][:destination_url] = origin_url
      end
    end
  end
end