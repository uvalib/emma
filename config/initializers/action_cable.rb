# config/initializers/action_cable.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Setup and initialization for ActionCable.

ActionCable::Server::Base.config.logger =
  Log.new(progname: 'SOCK', level: (DEBUG_CABLE ? Log::DEBUG : Log::INFO))
