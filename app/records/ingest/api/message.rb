# app/records/ingest/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for outbound messages to the EMMA Federated Ingestion API.
#
class Ingest::Api::Message < Ingest::Api::Record

  include Api::Message

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Api::Record, Hash, String, nil] src
  # @param [Hash]                                              opt
  #
  def initialize(src, **opt)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      initialize_attributes unless src.is_a?(Api::Record)
      apply_wrap!(opt)
      super(src, **opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Update *opt[:wrap]* according to the supplied formats.
  #
  # @param [Hash] opt                 May be modified.
  # @param [Hash] formats             Supplied by subclass.
  #
  # @return [void]
  #
  def apply_wrap!(opt, formats = nil)
    return if formats.blank?
    if opt[:wrap].nil?
      opt[:wrap] = formats
    elsif opt[:wrap].is_a?(Hash)
      opt[:wrap] = formats.merge(opt[:wrap])
    end
  end

end

__loading_end(__FILE__)
