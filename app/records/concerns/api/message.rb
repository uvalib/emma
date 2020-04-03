# app/records/concerns/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# This module is included in the base message classes.
#
# Since messages are slight variations on records, the base message classes
# derive from their respective record types, which is why this is a module and
# not a class.  However, because this module is included in the base message
# classes, `is_a?(Api::Message)` can be used to generically distinguish message
# instances from record instances.
#
module Api::Message

  include Emma::Time

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Annotate and time the creation of a message.
  #
  # @param [Hash, nil] opt
  #
  # @option opt [Boolean] :in_msg     If already engaged in message creation,
  #                                     avoid additional pre- and post-actions.
  #
  # @yield Block in which message creation actions take place.
  # @yieldparam [Hash] opt            Option hash to use within block.
  # @yieldreturn [void]
  #
  def create_message_wrapper(opt = nil, &block)
    (opt && opt[:in_msg]) ? yield(opt) : create_message(opt, &block)
  end

  # Annotate and time the creation of a message.
  #
  # @param [Hash, nil] opt
  #
  # @yield Block in which message creation actions take place.
  # @yieldparam [Hash] opt            Option hash to use within block.
  # @yieldreturn [void]
  #
  def create_message(opt)
    __debug { "### #{self.class}.#{__method__}" }
    start_time = timestamp
    opt = opt&.dup || {}
    opt[:in_msg] = true
    yield(opt)
  ensure
    elapsed_time = time_span(start_time)
    __debug  { "<<< #{self.class} processed in #{elapsed_time}" }
    Log.info { "#{self.class} processed in #{elapsed_time}"}
  end

end

__loading_end(__FILE__)
