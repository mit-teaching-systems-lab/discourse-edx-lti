# ---------------------------------------------------------------
# name:  discourse-omniauth-lti
# about: Discourse plugin to authenticate with LTI (eg., for an EdX course)
# version: 0.0.1
# author: MIT Teaching Systems Lab
# url: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
# ---------------------------------------------------------------

PLUGIN_NAME = 'discourse-omniauth-lti'.freeze
after_initialize do
  # Plugins need to explicitly include their dependencies, and the loading
  # mechanism is different than with bundler.
  # See https://github.com/discourse/discourse/blob/master/lib/plugin_gem.rb
  gem 'ims-lti', '1.1.13', require: false, require_name: 'ims/lti'


  # Add an endpoint that will redirect to the EdX URL.
  #
  # This uses a separate endpoint so that we can respond to changes in a `SiteSetting`
  # as soon as an admin user changes them in the UI.  If we passed in the `custom_url`
  # value into the auth_provider at boot time, we'd need to restart the server to pick
  # up the new value.
  #
  # It uses an Engine since just drawing the route led to problems with loading the
  # controller class.
  module ::DiscourseOmniauthLti
    class Engine < ::Rails::Engine
      engine_name PLUGIN_NAME
      isolate_namespace DiscourseOmniauthLti
    end
  end
  DiscourseOmniauthLti::Engine.routes.draw do
    get '/redirect_to_consumer' => 'lti#redirect_to_consumer'
  end
  Discourse::Application.routes.append do
    mount ::DiscourseOmniauthLti::Engine, at: '/lti'
  end

  require_dependency 'application_controller'
  class ::DiscourseOmniauthLti::LtiController < ::ApplicationController
    requires_plugin PLUGIN_NAME

    # Adapted from Discourse's StaticController#enter
    skip_before_filter :check_xhr, :redirect_to_login_if_required, :verify_authenticity_token

    def redirect_to_consumer
      url = SiteSetting.lti_consumer_authenticate_url
      puts "LtiController: redirecting to #{url}..."
      redirect_to url
      # Rails.logger :error, "LtiController: redirecting to #{url}..."
      

      # fdsfdsf.sdf.dsf.dsf.dsf.ds.fds
      # url = SiteSetting.lti_consumer_authenticate_url
      # Rails.logger :error, "LtiController: redirecting to #{url}..."
    end
  end


  # Enable site settings in admin UI.
  # We can't put the EdX URL in SiteSetting since it needs to be available at plugin
  # registry time.
  enabled_site_setting :lti_consumer_key
  enabled_site_setting :lti_consumer_secret
  enabled_site_setting :lti_consumer_authenticate_url


  # Register Discourse AuthProvider
  require_relative 'strategy.rb'
  require_relative 'authenticator.rb'
  auth_provider({
    title: 'Click to login with EdX',
    message: 'Click to login with EdX',
    authenticator: LTIAuthenticator.new,
    full_screen_login: true,
    custom_url: '/lti/redirect_to_consumer'
  })


  # This styles the login button, and overrides #login-form to
  # adds a little more separation between the EdX login button and
  # the the normal login form below (which is only for admin users).
  register_css <<CSS

  .btn-social.lti {
    height: 38px;
    font-size: 16px;
    text-align: left;
    color: white;
    background-color: rgb(183, 38, 103);
    background-size: 32px;
    background-repeat: no-repeat;
    background-position-x: 10px;
  }

  #login-form {
      border-top: 2px solid #eee;
      padding-top: 40px;
  }
CSS
end