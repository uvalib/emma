# app/records/concerns/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the Bookshare API.
#
# Api::Message instances must be created with data; if it is nil, :error option
# will be set and the derived class should modify its initialization
# accordingly.
#
class Api::Message < ::Api::Record

  include TimeHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Hash, String] data
  # @param [Hash]                            opt
  #
  # @option opt [Symbol] :format      If not provided, this will be determined
  #                                     heuristically from *data*.
  #
  # This method overrides:
  # @see Api::Record#initialize
  #
  # noinspection RubyYardParamTypeMatch
  def initialize(data, **opt)
    __debug { "### #{self.class}.#{__method__}" }
    start_time = timestamp
    data = data.body.presence if data.is_a?(Faraday::Response)
    opt  = opt.dup
    opt[:format] ||= self.format_of(data)
    opt[:error]  ||= true if opt[:format].blank?
    data = wrap_outer(data, opt) if (opt[:format] == :xml) && !opt[:error]
    super(data, opt)
=begin # TODO: log exceptions?
  rescue Api::RecvError => e
    Log.error { "#{self.class.name}: #{e}" }
    raise e
  rescue => e
    Log.error { "#{self.class.name}: invalid input: #{e}" }
    raise Api::ParseError, e
=end
  ensure
    elapsed_time = time_span(start_time)
    __debug { "<<< #{self.class} processed in #{elapsed_time}" }
    Log.info { "#{self.class} processed in #{elapsed_time}"}
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

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
