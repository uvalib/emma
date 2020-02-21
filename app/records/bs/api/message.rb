# app/records/bs/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the Bookshare API.
#
# Bs::Api::Message instances must be created with data; if it is nil, :error
# option will be set and the derived class should modify its initialization
# accordingly.
#
class Bs::Api::Message < Bs::Api::Record

  include ::Api::Message

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
  # @see Bs::Api::Record#initialize
  #
  # noinspection RubyYardParamTypeMatch
  def initialize(data, **opt)
    create_message do
      data = data.body.presence if data.is_a?(Faraday::Response)
      opt[:format] ||= self.format_of(data)
      opt[:error]  ||= true if opt[:format].blank?
      data = wrap_outer(data, **opt) if (opt[:format] == :xml) && !opt[:error]
      super(data, **opt)
    end
  end

end

__loading_end(__FILE__)
