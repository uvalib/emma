# config/initializers/omniauth.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for OmniAuth.
#
# @see lib/ext/omniauth/lib/omniauth/configuration.rb

OmniAuth.config.logger     ||= Log.new(progname: 'OMNIAUTH')
OmniAuth.config.logger.level = Log::DEBUG if DEBUG_OAUTH

# Used by SessionsHelper#get_sessions_label:
OmniAuth.config.add_camelization 'emma',  'EMMA'
OmniAuth.config.add_camelization 'local', 'EMMA'
