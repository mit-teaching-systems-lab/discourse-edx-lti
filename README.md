# discourse-omniauth-lti
Discourse plugin supporting LTI with EdX courses

## Initial setup for new course forums
- Sign up for MailGun account
- Add DNS Record for email (eg., in AWS Route 53)
- Follow the 30-minute Digital Ocean install process
- Add DNS Record for server instance
- Test!

## Add SSL
- Setup SSL with Let's Encrypt: https://meta.discourse.org/t/setting-up-lets-encrypt/40709
- Rebuild container
- Test!

## Setup LTI with this plugin
- Plugin is here: https://github.com/mit-teaching-systems-lab/discourse-omniauth-lti
- Add plugin like this: https://meta.discourse.org/t/install-a-plugin/19157
- Rebuild container
- Test!

## EdX setup
- `Advanced settings` -> `Advanced Module List` -> add "lti" and "lti_consumer"
- Pick an id for the Forums, generate a consumer key and secret, and add those to `LTI Passports`
- In Studio, add an LTI consumer and make sure to set "Request users' username" and "Request user's email" to true