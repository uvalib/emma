# app/services/lookup_service/google_books.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Get results from the Google Books API.
#
# @see "en.emma.service.lookup.google_books"
#
class LookupService::GoogleBooks < LookupService::RemoteService

  include LookupService::GoogleBooks::Properties
  include LookupService::GoogleBooks::Action
  include LookupService::GoogleBooks::Common
  include LookupService::GoogleBooks::Definition

  # ===========================================================================
  # :section: LookupService::RemoteService overrides
  # ===========================================================================

  public

  # Fetch results from Google Books.
  #
  # @param [LookupService::Request] req  Def.: `@request`.
  #
  # @return [Lookup::GoogleBooks::Message::List]
  #
  def fetch(req = self.request)
    get_volumes(req)
  end

  # Transform response message data into a normalized data object.
  #
  # @param [Lookup::GoogleBooks::Api::Message,LookupService::Data,Hash,nil] msg
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Data]
  # @return [nil]                     If *msg* is *nil*.
  #
  def transform(msg, extended: false)
    case msg
      when LookupService::Data, Lookup::GoogleBooks::Api::Message
        # OK as is.
      else
        msg = Lookup::GoogleBooks::Message::List.new(msg)
    end
    super
  end

end

__loading_end(__FILE__)
