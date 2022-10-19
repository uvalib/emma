# app/services/lookup_service/crossref.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Get results from the Crossref API.
#
# @see "en.emma.service.lookup.crossref"
#
# @see https://api.crossref.org/
# @see https://www.crossref.org/documentation/retrieve-metadata/rest-api/
#
class LookupService::Crossref < LookupService::RemoteService

  # Include send/receive modules from "lookup_service/crossref/**.rb".
  include_submodules(self)

  # ===========================================================================
  # :section: LookupService::RemoteService overrides
  # ===========================================================================

  public

  # Fetch results from Crossref.
  #
  # @param [LookupService::Request] req  Def.: `@request`.
  #
  # @return [Lookup::Crossref::Message::WorkResults]
  # @return [Lookup::Crossref::Message::Work]
  # @return [Lookup::Crossref::Message::Error]
  #
  # == Usage Notes
  # The items are assumed to be in the proper form.
  #
  def fetch(req = self.request)
    dois, other = req.values.partition { |id| id.is_a?(Doi) }
    if (dois.size == 1) && other.blank?
      get_work(dois.first)
    else
      get_work_list(req)
    end
  rescue => error
    Log.info do
      "#{self.class}.#{__method__}: req: #{req.inspect}; " \
      "#{error.class}: #{error.message}"
    end
    raise error unless error.is_a?(ApiService::Error)
    Lookup::Crossref::Message::Error.new(error)
  end

  # Transform response message data into a normalized data object.
  #
  # @param [Lookup::Crossref::Api::Message, LookupService::Data, Hash, nil] msg
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Data]
  # @return [nil]                     If *msg* is *nil*.
  #
  def transform(msg, extended: false)
    case msg
      when LookupService::Data, Lookup::Crossref::Api::Message
        # OK as is.
      else
        msg = Lookup::Crossref::Message::Work.new(msg)
    end
    super(msg, extended: extended)
  end

  # ===========================================================================
  # :section: LookupService::RemoteService overrides
  # ===========================================================================

  protected

  # transform_single
  #
  # @param [Lookup::Crossref::Record::Work] rec
  #
  # @return [Hash]
  # @return [nil]                     If the record should be ignored.
  #
  def transform_single(rec)
    super(rec, **rec.identifier_related)
  end

end

__loading_end(__FILE__)
