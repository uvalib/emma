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

  include Api::Message

  include Bs::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope, RubyMismatchedParameterType
    create_message_wrapper(opt) do |opt|
      apply_wrap!(opt)
      super(src, **opt)
      initialize_exec_report(exception)
    end
  end

  # ===========================================================================
  # :section: Api::Message overrides
  # ===========================================================================

  protected

  # Strategy for pre-wrapping message data before de-serialization.
  #
  # @type [Hash{Symbol=>String,Boolean}]
  #
  WRAP_FORMATS = { xml: true }.freeze

  # Update *opt[:wrap]* according to the supplied formats.
  #
  # @param [Hash] opt                 May be modified.
  #
  # @return [void]
  #
  def apply_wrap!(opt)
    super(opt, WRAP_FORMATS)
  end

end

__loading_end(__FILE__)
