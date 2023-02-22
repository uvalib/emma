# app/models/upload/emma_data_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record methods to support management of EMMA metadata fields.
#
module Upload::EmmaDataMethods

  include Emma::Json

  include Upload::WorkflowMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Core table columns.                                                         # NOTE: not relevant to Entry/Phase/Action.
  #
  # @type [Array<Symbol>]
  #
  DATA_COLUMNS = %i[file_data emma_data fmt ext user_id].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with EMMA metadata presented by
  # the record.
  #
  # @return [Symbol]
  #
  def emma_data_column                                                          # NOTE: not relevant to Entry/Phase/Action.
    edit_phase ? :edit_emma_data : :emma_data
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The EMMA metadata currently associated with the record.
  #
  # @return [String, nil]
  #
  def active_emma_data                                                          # NOTE: not relevant to Entry/Phase/Action.
    self[emma_data_column]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Present :emma_data as a structured object (if it is present).
  #
  # @param [Boolean] refresh          If *true*, force regeneration.
  #
  # @return [Search::Record::MetadataRecord]
  #
  def emma_record(refresh: false)
    @emma_record = nil if refresh
    @emma_record ||= make_emma_record(emma_metadata(refresh: true))
  end

  # Present :emma_data as a hash (if it is present).
  #
  # @param [Boolean] refresh          If *true*, force regeneration.
  #
  # @return [Hash]
  #
  def emma_metadata(refresh: false)
    @emma_metadata = nil if refresh
    @emma_metadata ||= parse_emma_data(emma_data, true)
  end

  # Set the :emma_data field value.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  # @param [Boolean]                                           allow_blank
  #
  # @return [String]
  # @return [nil]                     If *data* is *nil*.
  #
  def set_emma_data(data, allow_blank = false)                                  # NOTE: to Record::EmmaData::InstanceMethods
    @emma_record     = nil # Force regeneration.
    @emma_metadata   = parse_emma_data(data, allow_blank)
    self[:emma_data] = @emma_metadata.presence&.to_json
  end

  # Selectively modify the :emma_data field value.
  #
  # @param [Hash]    data
  # @param [Boolean] allow_blank
  #
  # @return [String]
  #
  def modify_emma_data(data, allow_blank = false)                               # NOTE: to Record::EmmaData::InstanceMethods
    new_metadata = parse_emma_data(data, allow_blank)
    if new_metadata.present?
      @emma_record     = nil # Force regeneration.
      @emma_metadata   = emma_metadata.merge(new_metadata)
      self[:emma_data] = @emma_metadata.to_json
    end
    self[:emma_data]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Present :edit_emma_data as a structured object (if it is present).
  #
  # @return [Search::Record::MetadataRecord]
  #
  def edit_emma_record                                                          # NOTE: not relevant to Entry/Phase/Action.
    @edit_emma_record ||= make_emma_record(edit_emma_metadata)
  end

  # Present :edit_emma_data as a hash (if it is present).
  #
  # @return [Hash]
  #
  def edit_emma_metadata                                                        # NOTE: not relevant to Entry/Phase/Action.
    @edit_emma_metadata ||= parse_emma_data(edit_emma_data, true)
  end

  # Set the :edit_emma_data field value.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  # @param [Boolean]                                           allow_blank
  #
  # @return [String]
  # @return [nil]                     If *data* is *nil*.
  #
  def set_edit_emma_data(data, allow_blank = false)                             # NOTE: not relevant to Entry/Phase/Action.
    @edit_emma_record     = nil # Force regeneration.
    @edit_emma_metadata   = parse_emma_data(data, allow_blank)
    self[:edit_emma_data] = @edit_emma_metadata.presence&.to_json
  end

  # Selectively modify the :edit_emma_data field value.
  #
  # @param [Hash]    data
  # @param [Boolean] allow_blank
  #
  # @return [String]
  #
  def modify_edit_emma_data(data, allow_blank = false)                          # NOTE: not relevant to Entry/Phase/Action.
    new_metadata = parse_emma_data(data, allow_blank)
    if new_metadata.present?
      @edit_emma_record     = nil # Force regeneration.
      @edit_emma_metadata   = edit_emma_metadata.merge(new_metadata)
      self[:edit_emma_data] = @edit_emma_metadata.to_json
    end
    self[:edit_emma_data]
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Present the EMMA data currently associated with the record as a
  # structured object.
  #
  # @return [Search::Record::MetadataRecord]
  #
  def active_emma_record                                                        # NOTE: not relevant to Entry/Phase/Action.
    edit_phase ? edit_emma_record : emma_record
  end

  # Present the EMMA data currently associated with the record as a hash.
  #
  # @return [Hash]
  #
  def active_emma_metadata                                                      # NOTE: not relevant to Entry/Phase/Action.
    edit_phase ? edit_emma_metadata : emma_metadata
  end

  # Set the EMMA data currently associated with the record.
  #
  # @param [Search::Record::MetadataRecord, Hash, String, nil] data
  # @param [Boolean]                                           allow_blank
  #
  # @return [String]
  # @return [nil]                     If *data* is *nil*.
  #
  def set_active_emma_data(data, allow_blank = false)                           # NOTE: not relevant to Entry/Phase/Action.
    if edit_phase
      set_edit_emma_data(data, allow_blank)
    else
      set_emma_data(data, allow_blank)
    end
  end

  # Selectively modify the EMMA data currently associated with the record.
  #
  # @param [Hash]    data
  # @param [Boolean] allow_blank
  #
  # @return [String]
  #
  def modify_active_emma_data(data, allow_blank = false)                        # NOTE: not relevant to Entry/Phase/Action.
    if edit_phase
      modify_edit_emma_data(data, allow_blank)
    else
      modify_emma_data(data, allow_blank)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate a record to express structured EMMA data.
  #
  # @param [Hash] data
  #
  # @return [Search::Record::MetadataRecord]
  #
  def make_emma_record(data, **)                                                    # NOTE: to Record::EmmaData
    Search::Record::MetadataRecord.new(data)
  end

  # parse_emma_data
  #
  # @param [Search::Record::MetadataRecord, String, Hash, ActionController::Parameters, Model, nil] data
  # @param [Boolean] allow_blank
  #
  # @return [Hash]
  #
  def parse_emma_data(data, allow_blank = false)                                # NOTE: to Record::EmmaData
    return {} if data.blank?
    result =
      case data
        when Search::Record::MetadataRecord
          data.as_json
        when Model
          data.as_json(only: Search::Record::MetadataRecord.field_names)
        else
          data
      end
    result = json_parse(result, no_raise: false) || {}
    result = reject_blanks(result) unless allow_blank
    result.map { |k, v|
      v     = Array.wrap(v)
      prop  = Field.configuration_for(k, :upload)
      array = prop[:array]
      type  = prop[:type]
      join  = "\n"
      sep   = /[|\t\n]+/
      if %i[dc_identifier dc_relation].include?(k)
        v = PublicationIdentifier.split(v)
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

end

__loading_end(__FILE__)
