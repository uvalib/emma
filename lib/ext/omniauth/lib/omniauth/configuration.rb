# lib/ext/omniauth/lib/omniauth/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the OmniAuth gem.

__loading_begin(__FILE__)

require 'omniauth'

module OmniAuth

  class Configuration

    # Because OmniAuth::Configuration#defaults invokes this method
    # unconditionally, defining the local logger here in this override rather
    # than in 'config/initializers.rb' avoids creation of an extra unused
    # logger instance.
    #
    # @return [Emma::Logger]
    #
    def self.default_logger
      Log.new(progname: 'OMNIAUTH')
    end

  end

end

__loading_end(__FILE__)
