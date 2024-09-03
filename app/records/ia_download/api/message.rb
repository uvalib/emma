# app/records/ia_download/api/message.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# The base class for inbound messages from the Internet Archive
# "Printdisabled Unencrypted Ebook API".
#
class IaDownload::Api::Message < IaDownload::Api::Record

  include Api::Message

  include IaDownload::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Faraday::Response, Hash, nil] src
  # @param [Hash, nil]                    opt
  #
  def initialize(src, opt = nil)
    # noinspection RubyScope
    create_message_wrapper(opt) do |opt|
      super(src, **opt)
    end
  end

end

__loading_end(__FILE__)
