# app/controllers/concerns/params_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/log'

# Facilities for working with received URL parameters.
#
module ParamsConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'ParamsConcern')
  end

  TRUE_VALUES  = %w(1 yes true).freeze
  FALSE_VALUES = %w(0 no false).freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def true?(value)
    TRUE_VALUES.include?(value.to_s.strip.downcase)
  end

  # Indicate whether the item represents a true value.
  #
  # @param [String, Boolean] value
  #
  def false?(value)
    FALSE_VALUES.include?(value.to_s.strip.downcase)
  end

  # ===========================================================================
  # :section: Callbacks
  # ===========================================================================

  protected

  # If URL parameter 'logging=false' is included then excess logging will be
  # suppressed.
  #
  # @param [String, Boolean, nil] logging   Default: `params[:logging]`.
  #
  # @return [void]
  #
  # Paired with after_action:
  # @see #unsuppress_logger
  #
  def suppress_logger(logging = nil)
    logging = params[:logging] if logging.nil?
    @logger_suppressed = (false?(logging) unless logging.nil?)
    Log.silent(true) if @logger_suppressed
  end

  # Undo the effects of the before_action which suppressed excess logging.
  #
  # @return [void]
  #
  # Paired with before_action:
  # @see #suppress_logger
  #
  def unsuppress_logger
    Log.silent(false) if @logger_suppressed
    @logger_suppressed = nil
  end

end

__loading_end(__FILE__)
