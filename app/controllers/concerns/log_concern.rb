# app/controllers/concerns/log_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'emma/log'

# LogConcern
#
module LogConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'LogConcern')
  end

  include ParamsHelper

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
    Log.silent(false)
    @logger_suppressed = nil
  end

end

__loading_end(__FILE__)
