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
  # @yield Block in which message creation actions take place.
  # @yieldreturn [void]
  #
  def create_message
    __debug { "### #{self.class}.#{__method__}" }
    start_time = timestamp
    yield
  ensure
    elapsed_time = time_span(start_time)
    __debug { "<<< #{self.class} processed in #{elapsed_time}" }
    Log.info { "#{self.class} processed in #{elapsed_time}"}
  end

  # wrap_outer
  #
  # @param [String, Hash] data
  # @param [Hash]         opt
  #
  # @return [String, Hash]            Returned as the same type as *data*.
  #
  def wrap_outer(data, **opt)
    name = self.class.name.demodulize.camelcase(:lower)
    if data.is_a?(Hash)
      { name => data }
    elsif opt[:format] == :json
      %Q("#{name}":{#{data}})
    elsif data.start_with?('<?')
      data.sub(/^<\?.*?\?>/, '\0' + "<#{name}>") + "</#{name}>"
    else # opt[:format] == :xml
      "<#{name}>#{data}</#{name}>"
    end
  end

end

__loading_end(__FILE__)
