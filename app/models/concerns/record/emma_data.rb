# app/models/record/emma_data.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Record methods to support processing of EMMA metadata fields.
#
module Record::EmmaData

  extend ActiveSupport::Concern

  include Emma::Common
  include Emma::Json

  include Record
  include Record::EmmaIdentification

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The default name for the column that holds EMMA metadata values.
  #
  # @type [Symbol]
  #
  EMMA_DATA_COLUMN = :emma_data

  # Whether the #EMMA_DATA_COLUMN should be persisted as a Hash.
  #
  # @type [Boolean]
  #
  EMMA_DATA_HASH = true

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # EMMA data fields configuration.
  #
  # @type [Hash]
  #
  EMMA_DATA_CONFIG =
    config_section('emma.upload.record.emma_data').select { |_, v|
      v[:max].nil? || positive(v[:max]) if v.is_a?(Hash)
    }.deep_freeze

  # EMMA data field names.
  #
  # @type [Array<Symbol>]
  #
  EMMA_DATA_KEYS = EMMA_DATA_CONFIG.keys.freeze

  # EMMA data fields that default to the current time.
  #
  # @type [Array<Symbol>]
  #
  DEFAULT_TIME_NOW_FIELDS = %i[
    emma_lastRemediationDate
    emma_repositoryMetadataUpdateDate
    emma_repositoryUpdateDate
    rem_remediationDate
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a URL for use with :emma_retrievalLink.
  #
  # @param [String, nil]      rid       EMMA repository record ID.
  # @param [String, Hash nil] base_url  Default: `Upload#BULK_BASE_URL`.
  #
  # @return [String]
  # @return [nil]                       If no repository ID was given.
  #
  # @note From Upload#make_retrieval_link
  #
  def make_retrieval_link(rid, base_url = nil)
    return if rid.blank?
    base_url   = base_url[:base_url] if base_url.is_a?(Hash)
    base_url ||= Upload::BULK_BASE_URL
    # noinspection RubyMismatchedArgumentType
    File.join(base_url, 'download', rid).to_s
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a record to express structured EMMA data.
  #
  # @param [Hash] data
  #
  # @return [Search::Record::MetadataRecord]
  #
  # @note From Upload::EmmaDataMethods#make_emma_record
  #
  def make_emma_record(data, **)
    Search::Record::MetadataRecord.new(data)
  end

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, Model, Hash, String, nil] data
  # @param [Boolean] allow_blank
  #
  # @return [Hash]
  #
  # @note From Upload::EmmaDataMethods#parse_emma_data
  #
  def parse_emma_data(data, allow_blank = false)
    case data
      when Search::Record::MetadataRecord
        result = data.as_json
      when Model
        result = data.as_json(only: Search::Record::MetadataRecord.field_names)
      else
        result = data
    end
    result = json_parse(result, fatal: true) or return {}
    reject_blanks!(result) unless allow_blank
    result.map { |k, v|
      v     = Array.wrap(v)
      prop  = Field.configuration_for(k, :upload)
      array = prop[:array]
      type  = prop[:type]
      join  = "\n"
      sep   = /[|\t\n]+/
      if %i[dc_identifier dc_relation].include?(k)
        v = PublicationIdentifier.split(v)
      elsif type == 'json'
        v = v.join(join).strip
      elsif (type == 'boolean') || (type == TrueFalse)
        v = v.first
        v = true?(v) unless v.nil?
      elsif (lines = (type == 'textarea')) || (type == 'text') || type.blank?
        join = sep = ';' unless lines
        if array
          v = v.join(join).split(sep).map!(&:strip).compact_blank!
        else
          v = v.map(&:to_s).map!(&:strip).compact_blank!.join(join)
        end
      else
        v = v.join(join).split(sep).map!(&:strip).compact_blank!
      end
      v = v.first if v.is_a?(Array) && !array
      [k, v] if allow_blank || v.present? || v.is_a?(FalseClass)
    }.compact.sort.to_h.tap { |hash|
      Api::Shared::TransformMethods.normalize_data_fields!(hash)
    }
  rescue => error
    Log.warn do
      msg = [__method__, error.message]
      msg << "for #{data.inspect}" if Log.debug?
      msg.join(': ')
    end
    re_raise_if_internal_exception(error) or {}
  end

  # generate_emma_data
  #
  # @param [Search::Record::MetadataRecord, Model, Hash, String, nil] data
  # @param [Search::Record::MetadataRecord, Model, Hash, String, nil] attr
  #
  # @return [Hash]
  #
  # @note From Upload#assign_attributes (sorta)
  #
  #--
  # noinspection RubyMismatchedArgumentType
  #++
  def generate_emma_data(data, attr)
    data  = data&.dup || {}
    utime = attr&.dig(:updated_at) || DateTime.now

    aed   = json_parse(attr&.dig(:emma_data))
    data  = aed.merge(data) if aed.is_a?(Hash)
    data  = parse_emma_data(data)

    # Augment supplied attribute values with supplied EMMA metadata.
    data[:emma_repository] ||= repository_value(attr)
    DEFAULT_TIME_NOW_FIELDS.each { |f| data[f] ||= utime if data.key?(f) }

    # EMMA metadata defaults that are only appropriate for EMMA-native items.
    if emma_native?(attr)
      rid = data[:emma_repositoryRecordId] ||= sid_value(attr)
      data[:emma_retrievalLink] ||= make_retrieval_link(rid, attr)
    end

    # noinspection RubyMismatchedReturnType
    data
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Class methods automatically added to the including record class.
  #
  module ClassMethods
    include Record::EmmaData
  end

  # Instance implementations to be included if the schema has an
  # EMMA_DATA_COLUMN column.
  #
  module InstanceMethods

    include Record::EmmaData

    # =========================================================================
    # :section: Record::EmmaData overrides
    # =========================================================================

    public

    # @see Record::EmmaData#make_retrieval_link
    #
    def make_retrieval_link(rid = nil, base_url = nil)
      rid ||= emma_data[:emma_retrievalLink]
      super
    end

    # @see Record::EmmaData#generate_emma_data
    #
    def generate_emma_data(data, attr = nil)
      attr ||= self
      super
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Present :emma_data as a structured object (if it is present).
    #
    # @param [Boolean] refresh     If *true*, force regeneration.
    #
    # @return [Search::Record::MetadataRecord]
    #
    # @note From Upload::EmmaDataMethods#emma_record
    #
    def emma_record(refresh: false)
      @emma_record = nil if refresh
      @emma_record ||= make_emma_record(emma_metadata(refresh: refresh))
    end

    # Present :emma_data as a hash (if it is present).
    #
    # @param [Boolean] refresh        If *true*, force regeneration.
    #
    # @return [Hash{Symbol=>*}]
    #
    # @note From Upload::EmmaDataMethods#emma_metadata
    #
    def emma_metadata(refresh: false)
      @emma_metadata = nil if refresh
      @emma_metadata ||= parse_emma_data(emma_data, true)
    end

    # Set the :emma_data field value (if not #EMMA_DATA_HASH).
    #
    # @param [Search::Record::MetadataRecord, Hash, String, nil] data
    # @param [Boolean]                                           allow_blank
    #
    # @return [String]                New value of :emma_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    # @note From Upload::EmmaDataMethods#set_emma_data
    #
    def set_emma_data(data, allow_blank = true)
      @emma_record     = nil # Force regeneration.
      @emma_metadata   = parse_emma_data(data, allow_blank)
      self[:emma_data] =
        case data
          when nil    then data
          when String then data.dup
          else             @emma_metadata.to_json
        end
    end

    # Selectively modify the :emma_data field value (if not #EMMA_DATA_HASH).
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [String]                New value of :emma_data.
    # @return [nil]                   If no change and :emma_data was *nil*.
    #
    # @note From Upload::EmmaDataMethods#modify_emma_data
    #
    def modify_emma_data(data, allow_blank = true)
      if (new_metadata = parse_emma_data(data, allow_blank)).present?
        @emma_record     = nil # Force regeneration.
        @emma_metadata   = emma_metadata.merge(new_metadata)
        self[:emma_data] = @emma_metadata.to_json
      end
      self[:emma_data]
    end

  end

  module InstanceMethods

    # Set the :emma_data field value hash.
    #
    # @param [Search::Record::MetadataRecord, Hash, String, nil] data
    # @param [Boolean]                                           allow_blank
    #
    # @return [Hash{String=>*}]       New value of :emma_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    def set_emma_data(data, allow_blank = true)
      @emma_record     = nil # Force regeneration.
      @emma_metadata   = parse_emma_data(data, allow_blank)
      self[:emma_data] = data && @emma_metadata.deep_stringify_keys
    end

    # Selectively modify the :emma_data field value hash.
    #
    # @param [Hash]    data
    # @param [Boolean] allow_blank
    #
    # @return [Hash{String=>*}]       New value of :emma_data
    # @return [nil]                   If no change and :emma_data was *nil*.
    #
    def modify_emma_data(data, allow_blank = true)
      if (new_metadata = parse_emma_data(data, allow_blank)).present?
        @emma_record     = nil # Force regeneration.
        @emma_metadata   = emma_metadata.merge(new_metadata)
        self[:emma_data] = @emma_metadata.deep_stringify_keys
      end
      self[:emma_data]
    end

  end if EMMA_DATA_HASH

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    include InstanceMethods if has_column?(EMMA_DATA_COLUMN)

  end

end

__loading_end(__FILE__)
