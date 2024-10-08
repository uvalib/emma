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
  include Emma::Constants
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

  # Fallback URL base.
  #
  # @type [String]
  #
  BULK_BASE_URL = PRODUCTION_URL

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a URL for use with :emma_retrievalLink.
  #
  # @param [String, nil]      rid       EMMA repository record ID.
  # @param [String, Hash nil] base_url  Default: `#BULK_BASE_URL`.
  #
  # @return [String]
  # @return [nil]                       If no repository ID was given.
  #
  def make_retrieval_link(rid, base_url = nil)
    return if rid.blank?
    base_url = base_url[:base_url] if base_url.is_a?(Hash)
    base_url = BULK_BASE_URL       if base_url.blank?
    make_path(base_url, 'download', rid)
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
  def make_emma_record(data, **)
    Search::Record::MetadataRecord.new(data)
  end

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, Model, Hash, String, nil] data
  # @param [Boolean]                                                  blanks
  #
  # @return [Hash]
  #
  def parse_emma_data(data, blanks: false)
    case data
      when Search::Record::MetadataRecord
        result = data.as_json
      when Model
        result = data.as_json(only: Search::Record::MetadataRecord.field_names)
      else
        result = data
    end
    result  = json_parse(result, fatal: true) or return {}
    reject_blanks!(result) unless blanks
    removed = result.select { |_, v| v == DELETED_FIELD }
    result.except(*removed.keys).map { |k, v|
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
          v = v.join(join).split(sep).map!(&:strip).compact_blank
        else
          v = v.map { _1.to_s.strip }.compact_blank.join(join)
        end
      else
        v = v.join(join).split(sep).map!(&:strip).compact_blank
      end
      v = v.first if v.is_a?(Array) && !array
      [k, v] if blanks || v.present? || v.is_a?(FalseClass)
    }.compact.sort.to_h.tap { |hash|
      Api::Shared::TransformMethods.normalize_data_fields!(hash)
    }.merge!(removed)
  rescue => error
    Log.warn do
      msg = [__method__, error.message]
      msg << "for #{data.inspect}" if Log.debug?
      msg.join(': ')
    end
    re_raise_if_internal_exception(error) or {}
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
    def emma_record(refresh: false)
      @emma_record = nil if refresh
      @emma_record ||= make_emma_record(emma_metadata(refresh: refresh))
    end

    # Present :emma_data as a hash (if it is present).
    #
    # @param [Boolean] refresh        If *true*, force regeneration.
    #
    # @return [Hash]
    #
    def emma_metadata(refresh: false)
      @emma_metadata = nil if refresh
      @emma_metadata ||= parse_emma_data(emma_data, blanks: true)
    end

    # Set the :emma_data field value.
    #
    # @param [Search::Record::MetadataRecord, Hash, String, nil] data
    # @param [Boolean]                                           blanks
    #
    # @return [any]                   New value of :emma_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    def set_emma_data(data, blanks: true)
      @emma_record     = nil # Force regeneration.
      @emma_metadata   = parse_emma_data(data, blanks: blanks)
      self[:emma_data] = init_emma_data_value(data)
    end

    # Selectively modify the :emma_data field value.
    #
    # @param [Hash]    data
    # @param [Boolean] blanks
    #
    # @return [any]                   New value of :emma_data
    # @return [nil]                   If no change and :emma_data was *nil*.
    #
    def modify_emma_data(data, blanks: true)
      if (new_metadata = parse_emma_data(data, blanks: blanks)).present?
        @emma_record     = nil # Force regeneration.
        @emma_metadata   = merge_metadata(emma_metadata, new_metadata)
        self[:emma_data] = curr_emma_data_value
      end
      self[:emma_data]
    end

    # init_emma_data_value
    #
    # @param [any, nil] data
    #
    # @return [Hash{String=>any,nil}, String, nil]
    #
    def init_emma_data_value(data)
      must_be_overridden
    end

    # curr_emma_data_value
    #
    # @return [Hash{String=>any,nil}, String, nil]
    #
    def curr_emma_data_value
      must_be_overridden
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Merge metadata with deletions.
    #
    # @param [Hash] metadata      The element to update.
    # @param [Hash] updates       Additions/modifications/deletions.
    #
    # @return [Hash]              A modified copy of *metadata*.
    #
    def merge_metadata(metadata, updates)
      metadata.merge(updates).delete_if { |_, v| v == DELETED_FIELD }
    end

  end

  # Instance implementation overrides if EMMA_DATA_COLUMN is saved as 'json'.
  module HashEmmaData

    include InstanceMethods

    # =========================================================================
    # :section: InstanceMethods overrides
    # =========================================================================

    public

    # Set the :emma_data field value hash.
    #
    # @param [Search::Record::MetadataRecord, Hash, String, nil] data
    # @param [Boolean]                                           blanks
    #
    # @return [Hash{String=>any,nil}] New value of :emma_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    def set_emma_data(data, blanks: true)
      super
    end

    # Selectively modify the :emma_data field value hash.
    #
    # @param [Hash]    data
    # @param [Boolean] blanks
    #
    # @return [Hash{String=>any,nil}] New value of :emma_data
    # @return [nil]                   If no change and :emma_data was *nil*.
    #
    def modify_emma_data(data, blanks: true)
      super
    end

    # init_emma_data_value
    #
    # @param [any, nil] data
    #
    # @return [Hash{String=>any,nil}, nil]
    #
    def init_emma_data_value(data)
      data.presence && curr_emma_data_value
    end

    # curr_emma_data_value
    #
    # @return [Hash{String=>any,nil}, nil]
    #
    def curr_emma_data_value
      @emma_metadata&.deep_stringify_keys
    end

  end

  # Instance implementation overrides if EMMA_DATA_COLUMN is saved as 'text'.
  module StringEmmaData

    include InstanceMethods

    # =========================================================================
    # :section: InstanceMethods overrides
    # =========================================================================

    public

    # Set the :emma_data field value.
    #
    # @param [Search::Record::MetadataRecord, Hash, String, nil] data
    # @param [Boolean]                                           blanks
    #
    # @return [String]                New value of :emma_data
    # @return [nil]                   ...if *data* is *nil*.
    #
    def set_emma_data(data, blanks: true)
      super
    end

    # Selectively modify the :emma_data field value.
    #
    # @param [Hash]    data
    # @param [Boolean] blanks
    #
    # @return [String]                New value of :emma_data
    # @return [nil]                   If no change and :emma_data was *nil*.
    #
    def modify_emma_data(data, blanks: true)
      super
    end

    # init_emma_data_value
    #
    # @param [any, nil] data
    #
    # @return [String, nil]
    #
    def init_emma_data_value(data)
      case data
        when nil    then data
        when String then data.dup
        else             curr_emma_data_value
      end
    end

    # curr_emma_data_value
    #
    # @return [String, nil]
    #
    def curr_emma_data_value
      @emma_metadata&.to_json
    end

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|

    __included(base, THIS_MODULE)
    assert_record_class(base, THIS_MODULE)

    if has_column?(EMMA_DATA_COLUMN)

      include InstanceMethods

      if EMMA_DATA_HASH
        include HashEmmaData
      else
        include StringEmmaData
      end

    end

  end

end

__loading_end(__FILE__)
