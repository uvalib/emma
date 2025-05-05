# lib/ext/sprockets/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Sprockets gem.

__loading_begin(__FILE__)

require 'sprockets'

module Sprockets

  # Generate an override logger for Sprockets or its classes.
  #
  # @param [Logger, String, IO, nil] src    Old logger instance.
  # @param [Array]                   args   @see Emma::Logger#initialize
  # @param [Hash]                    opt    @see Emma::Logger#initialize
  #
  # @return [Emma::Logger]
  #
  def self.local_logger(src = STDERR, *args, **opt)
    opt[:progname] ||= 'SPROCKETS'
    opt[:level]    ||= Log::FATAL unless src.try(:level)
    unless rails_application?
      opt[:default_formatter] = ActiveSupport::Logger::SimpleFormatter.new
    end
    Log.new(src, *args, **opt)
  end

  @logger = local_logger(@logger)

end

require_subdirs(__FILE__)

__loading_end(__FILE__)
