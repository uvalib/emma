# app/controllers/concerns/data_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for database access.
#
module DataConcern

  extend ActiveSupport::Concern

  include Emma::Constants
  include ParamsHelper
  include DataHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Variations on the :tables parameter.
  #
  # @type [Array<Symbol>]
  #
  DATA_TABLE_PARAMETERS = %i[table]
    .flat_map { |v| [v.to_s.pluralize.to_sym, v] }.freeze

  # Variations on the :columns parameter.
  #
  # @type [Array<Symbol>]
  #
  DATA_COLUMN_PARAMETERS = %i[column field col]
    .flat_map { |v| [v.to_s.pluralize.to_sym, v] }.freeze

  # The normalized parameters.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMETERS = %i[html tables columns headings].freeze

  # The table holding EMMA submission entries.
  #
  # @type [String]
  #
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
  # @return [Hash{Symbol=>*}]
  #
  # === Usage Notes
  # Rails will set `params[:format]` if the URL is given with an extension
  # (even if a :format parameter was explicitly given); `data_params[:html]`
  # returns *true* if HTML was explicitly requested in either of these ways.
  #
  def data_params
    @data_params ||=
      request_parameters.tap do |prm|
        tables  = prm.extract!(*DATA_TABLE_PARAMETERS).compact.values.first
        columns = prm.extract!(*DATA_COLUMN_PARAMETERS).compact.values.first
        prm[:html]     = true?(prm[:html]) || (prm[:format] == 'html')
        prm[:tables]   = array_param(tables)&.map!(&:tableize)&.uniq
        prm[:tables]   = %i[all] if prm[:tables]&.include?('alls')
        prm[:columns]  = array_param(columns)&.map!(&:to_sym)&.uniq
        prm[:headings] = !false?(prm[:headings])
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
  def array_param(value)
    value = value.split(',')                      if value.is_a?(String)
    value.map { |s| s.to_s.strip }.compact_blank! if value.is_a?(Array)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Tables to be displayed after all others.
  #
  # @type [Array<String>]
  #
  LATER_TABLES = %w[schema_migrations ar_internal_metadata].freeze

  # Generate a hash of results for each table name.
  #
  # @param [Array<String,Symbol>] names   Default: `DataHelper#table_names`.
  # @param [Hash]                 opt     Passed to DataHelper#table_records.
  #
  # @return [Hash{String=>Array}]
  #
  def get_tables(*names, **opt)
    opt  = data_params.merge(**opt)
    cols = Array.wrap(opt.delete(:columns))
    tbls = Array.wrap(opt.delete(:tables)).map(&:to_s).presence
    tbls = table_names if tbls.nil? || tbls.include?('all')
    names.concat(tbls)
    names.sort_by! { |n| (i = LATER_TABLES.index(n)) ? ('~%03d' % i) : n }
    names.map! { |name| [name, table_records(name, *cols, **opt)] }.to_h
  end

  # Generate results for the indicated table.
  #
  # @param [String, Symbol, nil]  name  Default: `data_params[:tables].first`
  # @param [Array<String,Symbol>] cols  Column names; default: "*".
  # @param [Hash]                 opt   Passed to DataHelper#table_records.
  #
  # @return [Array>]
  #
  def get_table_records(name = nil, *cols, **opt)
    opt  = data_params.merge(**opt)
    name = Array.wrap(opt.delete(:columns)).first || name
    cols.concat(Array.wrap(opt.delete(:columns)))
    table_records(name, *cols, **opt)
  end

  # Generate results for EMMA submissions, which currently comes from a
  # selection of fields from the 'uploads' table.
  #
  # When generating HTML, each record entry is an Array of field values;
  # otherwise each record entry is a Hash.
  #
  # @param [String, Symbol, nil] table  Passed to #submission_records
  # @param [Hash]                opt    Passed to #submission_records
  #
  # @return [Array]
  #
  def get_submission_records(table = nil, **opt)

    # If columns have been specified, they are applied after the records have
    # been acquired and filtered based on the expected set of columns.
    opt     = data_params.merge(**opt)
    columns = Array.wrap(opt.delete(:columns)).presence

    submission_records(table, **opt).tap do |_name, records|
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
    records = get_submission_records(**opt) || []
    records.each do |record|
      next unless (emma_data = safe_json_parse(record[:emma_data])).is_a?(Hash)
      emma_data.each_pair do |field, data|
        next unless all || EMMA_DATA_FIELDS.include?(field)
        entry = fields[field] ||= {}
        Array.wrap(data).flatten.each do |item|
          item = item.to_s.squish
          item = nil if item == EMPTY_VALUE
          entry[item] = entry[item]&.next || 1 unless item.blank?
        end
      end
    end
    # Sort field value entries in descending order by count.
    fields.compact_blank!.transform_values! do |counts|
      counts.sort_by { |value, count| [-count, value] }.to_h
    end
    # Sort resulting hash alphabetically by field name.
    fields.sort.to_h
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Generate results for submission pseudo records.
  #
  # @param [String, Symbol, nil] table     Default: #SUBMISSION_TABLE
  # @param [Hash]                opt       Passed to #get_table_records.
  #
  # @return [Array]
  #
  def submission_records(table = nil, **opt)
    table ||= SUBMISSION_TABLE
    get_table_records(table, **opt)
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
    columns &&= Array.wrap(columns).presence&.map(:to_sym)
    (columns || SUBMISSION_COLUMNS).excluding(:state)
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
      idx if columns.include?(col)
    }.compact
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # States which indicate that the submission is either complete or that it is
  # on track to becoming complete (in the case of submissions back to partner
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
  BOGUS_NOTE_WORDS = %w[FAKE].freeze

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
