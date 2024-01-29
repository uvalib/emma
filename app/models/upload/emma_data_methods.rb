# app/models/upload/emma_data_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Upload record methods to support management of EMMA metadata fields.
#
module Upload::EmmaDataMethods

  include Record::EmmaData
  include Record::EmmaData::StringEmmaData

  include Upload::WorkflowMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Core table columns.
  #
  # @type [Array<Symbol>]
  #
  DATA_COLUMNS = %i[file_data emma_data fmt ext user_id].freeze

  # Edit process table columns.
  #
  # @type [Array<Symbol>]
  #
  EDIT_COLUMNS = %i[edit_user edit_file_data edit_emma_data edited_at].freeze

  # Review process table columns.
  #
  # @type [Array<Symbol>]
  #
  REVIEW_COLUMNS =
    %i[review_user review_success review_comment reviewed_at].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The database column currently associated with EMMA metadata presented by
  # the record.
  #
  # @return [Symbol]
  #
  def emma_data_column
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
  def active_emma_data
    self[emma_data_column]
  end

  # ===========================================================================
  # :section: Record::EmmaData::StringEmmaData overrides
  # ===========================================================================

  public

  # init_emma_data_value
  #
  # @param [*] _data
  #
  # @return [String, nil]
  #
  def init_emma_data_value(_data)
    @emma_metadata.presence&.to_json
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Present :edit_emma_data as a structured object (if it is present).
  #
  # @return [Search::Record::MetadataRecord]
  #
  def edit_emma_record
    @edit_emma_record ||= make_emma_record(edit_emma_metadata)
  end

  # Present :edit_emma_data as a hash (if it is present).
  #
  # @return [Hash]
  #
  def edit_emma_metadata
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
  def set_edit_emma_data(data, allow_blank = false)
    @edit_emma_record     = nil # Force regeneration.
    @edit_emma_metadata   = parse_emma_data(data, allow_blank)
    self[:edit_emma_data] = init_edit_emma_data_value(data)
  end

  # Selectively modify the :edit_emma_data field value.
  #
  # @param [Hash]    data
  # @param [Boolean] allow_blank
  #
  # @return [String, nil]
  #
  def modify_edit_emma_data(data, allow_blank = false)
    new_metadata = parse_emma_data(data, allow_blank)
    if new_metadata.present?
      @edit_emma_record     = nil # Force regeneration.
      @edit_emma_metadata   = edit_emma_metadata.merge(new_metadata)
      self[:edit_emma_data] = curr_edit_emma_data_value
    end
    self[:edit_emma_data]
  end

  # init_edit_emma_data_value
  #
  # @param [*] _data
  #
  # @return [String, nil]
  #
  def init_edit_emma_data_value(_data)
    @edit_emma_metadata.presence&.to_json
  end

  # curr_edit_emma_data_value
  #
  # @return [String, nil]
  #
  def curr_edit_emma_data_value
    @emma_metadata&.to_json
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
  def active_emma_record
    edit_phase ? edit_emma_record : emma_record
  end

  # Present the EMMA data currently associated with the record as a hash.
  #
  # @return [Hash]
  #
  def active_emma_metadata
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
  def set_active_emma_data(data, allow_blank = false)
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
  # @return [String, nil]
  #
  def modify_active_emma_data(data, allow_blank = false)
    if edit_phase
      modify_edit_emma_data(data, allow_blank)
    else
      modify_emma_data(data, allow_blank)
    end
  end

end

__loading_end(__FILE__)
