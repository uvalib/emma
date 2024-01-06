# app/services/lookup_service/world_cat.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Get results from the OCLC/WorldCat API.
#
# @see "en.emma.service.lookup.world_cat"
#
class LookupService::WorldCat < LookupService::RemoteService

  include LookupService::WorldCat::Properties
  include LookupService::WorldCat::Action
  include LookupService::WorldCat::Common
  include LookupService::WorldCat::Definition

  # ===========================================================================
  # :section: LookupService::RemoteService overrides
  # ===========================================================================

  public

  # Fetch results from WorldCat.
  #
  # @param [LookupService::Request] req  Def.: `@request`.
  #
  # @return [Lookup::WorldCat::Message::Sru]
  # @return [Lookup::WorldCat::Message::Error]
  #
  def fetch(req = self.request)
    get_sru_records(req)
  rescue => error
    Log.info do
      "#{self.class}.#{__method__}: req: #{req.inspect}; " \
      "#{error.class}: #{error.message}"
    end
    raise error unless error.is_a?(ApiService::Error)
    Lookup::WorldCat::Message::Error.new(error)
  end

  # Transform response message data into a normalized data object.
  #
  # @param [Lookup::WorldCat::Api::Message, LookupService::Data, Hash, nil] msg
  # @param [Boolean] extended         If *true*, include :diagnostic.
  #
  # @return [LookupService::Data]
  # @return [nil]                     If *msg* is *nil*.
  #
  def transform(msg, extended: false)
    case msg
      when LookupService::Data, Lookup::WorldCat::Api::Message
        # OK as is.
      else
        msg = Lookup::WorldCat::Message::Sru.new(msg)
    end
    super
  end

  # ===========================================================================
  # :section: LookupService::RemoteService overrides
  # ===========================================================================

  protected

  # transform_single
  #
  # @param [Lookup::WorldCat::Api::Record] rec
  #
  # @return [Hash]
  # @return [nil]                     If the record should be ignored.
  #
  # === Implementation Notes
  # Some WorldCat records seem to be aggregates that reference many individual
  # printings, etc.  To avoid excess noise in the blended result, these records
  # are rejected here.
  #
  def transform_single(rec)
    if rec.is_a?(Lookup::WorldCat::Record::OclcDcs)
      rec.identifier_table.flat_map { |type, ids|
        (type == :isbn) ? ids.partition(&:isbn13?) : [ids]
      }.each { |type| return if type.many? }
    end
    super
  end

end

__loading_end(__FILE__)
