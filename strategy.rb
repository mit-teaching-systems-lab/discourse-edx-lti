# OmniAuth strategy.  By adding it in this namespace, OmniAuth will load it when
# we ask for the :lti provider.
module OmniAuth
  module Strategies
    class Lti
      include OmniAuth::Strategy

      # Credentials for connecting with LTI provider.
      option :consumer_key, 'foo_consumer_key'
      option :consumer_secret, 'foo_consumer_secret'
      option :rails_session_key, 'omniauth_lti_provider_rails_session_key'
      
      # These are the params that the LTI Tool Provider receives
      # in the LTI handoff.  The values here are set in `callback_phase`.
      uid { @lti_provider.user_id }
      info do
        {
          :name => @lti_provider.username,
          :email => @lti_provider.lis_person_contact_email_primary,
          :first_name => @lti_provider.lis_person_name_given,
          :last_name => @lti_provider.lis_person_name_family,
          :image => @lti_provider.user_image
        }
      end
      extra do
        { :raw_info => @lti_provider.to_params }
      end

      def callback_phase
        # Rescue more generic OAuth errors and scenarios
        begin
          log :info, 'callback_phase'
          @lti_provider = create_valid_lti_provider!(request)
          session[options.rails_session_key] = @lti_provider.to_params
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
        Rails.logger.send(method_symbol, "LTI: #{text}")
      end

      # Creates and LTI provider and validates the request, returning
      # an IMS LTI ToolProvider.
      #
      # Raising ActionController::BadRequest if it fails.
      def create_valid_lti_provider!(request)
        if request.request_method != 'POST'
          raise ActionController::BadRequest.new('Unsupported method')
        end

        log :info, "Checking LTI params for consumer_key #{options.consumer_key}: #{request.params}"
        consumer_key = request.params['oauth_consumer_key']
        if consumer_key != options.consumer_key
          raise ActionController::BadRequest.new('Invalid request')
        end

        lti_provider = IMS::LTI::ToolProvider.new(options.consumer_key, options.consumer_secret, request.params)

        if not lti_provider.valid_request?(request)
          raise ActionController::BadRequest.new('Invalid LTI request')
        end

        lti_provider
      end
    end
  end
end