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

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true }.freeze

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  # This method overrides:
  # @see Bs::Api::Record#initialize
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      if opt[:wrap].nil? || opt[:wrap].is_a?(Hash)
        opt[:wrap] = WRAP_FORMATS.merge(opt[:wrap] || {})
      end
      super(src, **opt)
    end
  end

end

__loading_end(__FILE__)
