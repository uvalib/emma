# app/records/lookup/crossref/message/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A pseudo-message for a lookup response error.
#
class Lookup::Crossref::Message::Error < Lookup::Crossref::Api::Message

  include Lookup::Crossref::Shared::ResponseMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  schema do
    has_one :code,   Integer
    has_one :status
    has_one :text
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  def initialize(src, opt = nil)
    if src.is_a?(Exception)
      opt = (opt || {}).reverse_merge(error: src)
      cod = (src.http_status if src.is_a?(Api::Error))
      txt = src.is_a?(ApiService::RequestError) ? 'NOT FOUND' : src.message
      src = { status: 'error', code: cod, text: txt }.compact
    end
    super(src, opt)
  end

end

__loading_end(__FILE__)
