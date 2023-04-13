# config/initializers/omniauth.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for OmniAuth.

OmniAuth.config.logger       = Log.new(progname: 'OMNIAUTH')
OmniAuth.config.logger.level = DEBUG_OAUTH ? Log::DEBUG : Log::INFO

# Used by SessionsHelper#get_sessions_label:
OmniAuth.config.add_camelization 'emma',  'EMMA'
OmniAuth.config.add_camelization 'local', 'EMMA'
