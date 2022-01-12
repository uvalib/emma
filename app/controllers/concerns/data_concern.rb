# app/controllers/concerns/data_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for database access.
#
module DataConcern

  extend ActiveSupport::Concern

  include ParamsHelper
  include DataHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  DATA_COLUMN_PARAMETERS = %i[columns fields cols].freeze
  DATA_PARAMETERS        = %i[html headings columns tables].freeze

  SUBMISSION_TABLE = 'uploads'
  SUBMISSION_COLUMNS = %i[
    id
    file_data
    emma_data
    user_id
    repository
    submission_id
    fmt
    ext
    state
    created_at
    updated_at
  ].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters for DataController.
  #
  # @return [Hash{Symbol=>Any}]
  #
  # == Usage Notes
  # Rails will set `params[:format]` if the URL is given with an extension
  # (even if a :format parameter was explicitly given); `data_params[:html]`
  # returns *true* if HTML was explicitly requested in either of these ways.
  #
  def data_params
    @data_params ||=
      request_parameters.tap do |prm|
        columns = partition_hash!(prm, *DATA_COLUMN_PARAMETERS).values.first
        prm[:columns]  = array_param(columns)&.map(&:to_sym)&.uniq
        prm[:tables]   = array_param(prm[:tables])&.map(&:tableize)&.uniq
        prm[:headings] = !false?(prm[:headings])
        prm[:html]     = true?(prm[:html]) || (prm[:format] == 'html')
        prm.slice!(*DATA_PARAMETERS)
        prm.compact!
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Interpret a parameter value as an array of values if possible.
  #
  # @param [Array, String, nil] value
  #
  # @return [Array<String>, nil]      *nil* if *value* is *nil*.
  #
  #--
  # noinspection RubyNilAnalysis
  #++
  def array_param(value)
    value = value.split(',')                        if value.is_a?(String)
    value.map { |s| s.to_s.strip.presence }.compact if value.is_a?(Array)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Tables to be displayed after all others.
  #
  # @type [Array<String>]
  #
  LATER_TABLES = %w(schema_migrations ar_internal_metadata).freeze

  # Generate a hash of results for each table name.
  #
  # @param [Array<String,Symbol>] names   Default: `DataHelper#table_names`.
  # @param [Hash]                 opt     Passed to DataHelper#table_records.
  #
  # @return [Hash{String=>Array}]
  #
  def get_tables(*names, **opt)
    opt   = data_params.merge(**opt)
    cols  = Array.wrap(opt.delete(:columns))
    tbls  = Array.wrap(opt.delete(:tables)).presence
    names = tbls&.dup || names.presence || table_names.dup
    names.sort_by! { |n| (i = LATER_TABLES.index(n)) ? ('~%03d' % i) : n }
    # noinspection RubyMismatchedReturnType
    names.map! { |name| [name, table_records(name, *cols, **opt)] }.to_h
  end

  # Generate results for the indicated table.
  #
  # @param [String, Symbol, nil] name   Default: `params[:id]`
  # @param [Hash]                opt    Passed to DataHelper#table_records.
  #
  # @return [Array<(String,Array)>]
  #
  def get_table_records(name = nil, **opt)
    opt  = data_params.merge(**opt)
    cols = Array.wrap(opt.delete(:columns))
    name = (name || params[:id]).to_s
    return name, table_records(name, *cols, **opt)
  end

  # Generate results for EMMA submissions, which currently comes from a
  # selection of fields from the 'uploads' table.
  #
  # When generating HTML, each record entry is an Array of field values;
  # otherwise each record entry is a Hash.
  #
  # @param [Hash] opt                 Passed to #submission_records
  #
  # @return [Array<(String,Array)>]
  #
  def get_submission_records(**opt)

    # If columns have been specified, they are applied after the records have
    # been acquired and filtered based on the expected set of columns.
    opt     = data_params.merge(**opt)
    columns = Array.wrap(opt.delete(:columns)).presence

    submission_records(**opt).tap do |_name, records|
      # noinspection RubyMismatchedArgumentType
      if records.first.is_a?(Hash)
        modify_submission_records!(records, columns)
      else
        modify_submission_records_for_html!(records, columns)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a list of counts for each EMMA data field found across all
  # submissions.
  #
  # @param [Boolean] all              If *true* also show values for fields
  #                                     which are not valid.
  # @param [Hash]    opt              Passed to #get_submission_records
  #
  # @return [Hash{Symbol=>Hash}]
  #
  def get_submission_field_counts(all: false, **opt)
    fields  = {}
    records = get_submission_records(**opt).last || []
    records.each do |record|
      next unless (emma_data = safe_json_parse(record[:emma_data])).is_a?(Hash)
      emma_data.each_pair do |field, data|
        next unless all || EMMA_DATA_FIELDS.include?(field)
        entry = fields[field] ||= {}
        Array.wrap(data).flatten.each do |item|
          item = item.to_s.squish
          item = nil if item == ModelHelper::Fields::EMPTY_VALUE
          entry[item] = entry[item]&.next || 1 unless item.blank?
        end
      end
    end
    # Sort field value entries in descending order by count.
    fields.compact_blank!.transform_values! { |counts|
      counts.sort_by { |value, count| [-count, value] }.to_h
    }
    # Sort resulting hash alphabetically by field name.
    fields.sort.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate results for submission pseudo records.
  #
  # @param [String, Symbol, nil] table_name   Default: #SUBMISSION_TABLE.
  # @param [Hash]                opt          Passed to #get_table_records.
  #
  # @return [Array<(String,Array)>]
  #
  def submission_records(table_name: nil, **opt)
    table_name ||= SUBMISSION_TABLE
    get_table_records(table_name, **opt)
  end

  # Filter out invalid submissions for values intended for JSON or XML output,
  # then limit the columns that will be included in the resultant records.
  #
  # @param [Array<Hash>]        records
  # @param [Array<Symbol>, nil] columns
  #
  # @return [Array<Hash>]
  #
  def modify_submission_records!(records, columns = nil)
    columns = submission_result_columns(columns)
    records.map! { |record|
      # Handle the first (schema) row separately.
      if (schema = record[:schema])
        schema[:file_data] = schema[:emma_data] = :json
        schema.slice!(*columns)
      else
        next if submission_incomplete?(record[:state])
        next if submission_bogus?(record[:emma_data])
        record.slice!(*columns)
      end
      record
    }.compact!
    records
  end

  # Filter out invalid submissions for values intended for HTML output, then
  # limit the columns that will be included in the resultant records.
  #
  # @param [Array<Array>]       records
  # @param [Array<Symbol>, nil] columns
  #
  # @return [Array<Array>]
  #
  #--
  # noinspection RubyInstanceMethodNamingConvention
  #++
  def modify_submission_records_for_html!(records, columns = nil)
    columns   = submission_result_indices(columns)
    state_idx = SUBMISSION_COLUMNS.index(:state)
    data_idx  = SUBMISSION_COLUMNS.index(:emma_data)
    records.map! { |record|
      # Skip evaluation of the first (schema) row.
      unless record.first == 'id'
        next if submission_incomplete?(record[state_idx])
        next if submission_bogus?(record[data_idx])
      end
      record.values_at(*columns)
    }.compact!
    records
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Enumerate the database columns which are relevant to data analysis output.
  #
  # @param [Array<Symbol>, Symbol, nil] columns   Default: #SUBMISSION_COLUMNS
  #
  # @return [Array<Symbol>]
  #
  def submission_result_columns(columns = nil)
    columns = Array.wrap(columns).presence&.map(:to_sym) || SUBMISSION_COLUMNS
    columns - %i[state]
  end

  # Enumerate the record array indicies which are relevant to data analysis.
  #
  # @param [Array<Symbol>, Symbol, nil] columns   Default: #SUBMISSION_COLUMNS
  #
  # @return [Array<Symbol>]
  #
  def submission_result_indices(columns = nil)
    columns = submission_result_columns(columns)
    SUBMISSION_COLUMNS.map.with_index { |col, idx|
      # noinspection RubyNilAnalysis
      idx if columns.include?(col)
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # States which indicate that the submission is either complete or that it is
  # on track to becoming complete (in the case of submissions back to member
  # repositories).
  #
  # @type [Array<Symbol>]
  #
  COMPLETION_STATES = %i[
    completed
    indexed
    indexing
    retrieved
    unretrieved
    staging
  ].freeze

  # Indicate whether the submission is not completed (or in the process of
  # being completed).
  #
  # @param [String, Symbol] state
  #
  def submission_incomplete?(state)
    state.present? && !COMPLETION_STATES.include?(state.to_sym)
  end

  # Title prefixes used in development/testing to denote submissions which are
  # not meant to be presented in search results.
  #
  # @type [Array<String>]
  #
  BOGUS_TITLE_PREFIXES = %w(RWL IA_BULK)

  # Words used in :rem_comments during development/testing to denote
  # submissions which are not meant to be presented in search results.
  #
  # @type [Array<String>]
  #
  BOGUS_NOTE_WORDS = %w(FAKE)

  # Indicate whether this submission appears to be non-canonical.
  #
  # @param [String, Hash] emma_data
  #
  def submission_bogus?(emma_data)
    data  = json_parse(emma_data) || {}
    title = data[:dc_title].to_s
    note  = data[:rem_comments].to_s
    title.blank? ||
      BOGUS_TITLE_PREFIXES.any? { |s| title.start_with?(s) } ||
      BOGUS_NOTE_WORDS.any? { |s| note.include?(s) }
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  THIS_MODULE = self

  included do |base|
    __included(base, THIS_MODULE)
  end

end

__loading_end(__FILE__)
