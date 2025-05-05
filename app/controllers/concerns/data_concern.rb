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

  # Variations on the :tables parameter.
  #
  # @type [Array<Symbol>]
  #
  DATA_TABLE_PARAMETERS = %i[table]
    .flat_map { [_1.to_s.pluralize.to_sym, _1] }.freeze

  # Variations on the :columns parameter.
  #
  # @type [Array<Symbol>]
  #
  DATA_COLUMN_PARAMETERS = %i[column field col]
    .flat_map { [_1.to_s.pluralize.to_sym, _1] }.freeze

  # The normalized parameters.
  #
  # @type [Array<Symbol>]
  #
  DATA_PARAMETERS = %i[html tables columns headings].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # URL parameters for DataController.
  #
  # @return [Hash]
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
        if prm.key?(:html)
          prm[:html] = true?(prm[:html])
        else
          prm[:html] = 'html'.casecmp?(prm[:format])
        end
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
    # noinspection RubyArgCount (RubyMine analyzer fails here)
    value = value.split(',')                  if value.is_a?(String)
    value.map { _1.to_s.strip }.compact_blank if value.is_a?(Array)
  end

  # Because DataHelper is biased toward assuming that non-HTML is expected,
  # defaulting to HTML format requires setting `params[:format]` to make it
  # appear as though a format has been explicitly requested.
  #
  # @param [Symbol, String] fmt
  #
  # @return [void]
  #
  def default_format(fmt)
    unless params[:format]
      params[:format] = fmt.to_s
      request.format  = fmt.to_sym
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Generate a hash of results for each table name.
  #
  # @param [Array<String,Symbol>] names   Default: `DataHelper#table_names`.
  # @param [Boolean]              sort    If *false*, do not sort by name.
  # @param [Hash]                 opt     Passed to DataHelper#table_records.
  #
  # @return [Hash{String=>Array}]
  #
  def get_tables(*names, sort: true, **opt)
    opt  = data_params.merge(**opt)
    cols = Array.wrap(opt.delete(:columns))
    tbls = Array.wrap(opt.delete(:tables)).map(&:to_s).presence
    tbls = table_names if tbls.nil? || tbls.include?('all')
    names.concat(tbls)
    names = sorted_table_names(names) if sort
    names.map! { [_1, table_records(_1, *cols, **opt)] }.to_h
  end

  # Generate results for the indicated table.
  #
  # @param [String, Symbol, nil]  name  Default: `data_params[:tables].first`
  # @param [Array<String,Symbol>] cols  Column names; default: "*".
  # @param [Hash]                 opt   Passed to DataHelper#table_records.
  #
  # @return [Array]
  #
  def get_table_records(name = nil, *cols, **opt)
    opt  = data_params.merge(**opt)
    name = Array.wrap(opt.delete(:tables)).first || name
    cols.concat(Array.wrap(opt.delete(:columns))) if opt.key?(:columns)
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
    records = submission_records(table, **opt)
    if records.first.is_a?(Hash)
      modify_submission_records!(records, columns)
    else
      modify_submission_records_for_html!(records, columns)
    end
  end

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
    records = get_submission_records(**opt, html: false) || []
    records.each do |record|
      next unless (emma_data = safe_json_parse(record[:emma_data])).is_a?(Hash)
      emma_data.slice!(*EMMA_DATA_FIELDS) unless all
      emma_data.each_pair do |field, data|
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
  # @param [String, Symbol, nil] table     Default: #submission_table
  # @param [Hash]                opt       Passed to #get_table_records.
  #
  # @return [Array]
  #
  def submission_records(table = nil, **opt)
    table ||= submission_table
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
        record[:schema] = schema
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
  def modify_submission_records_for_html!(records, columns = nil)
    indices   = submission_result_indices(columns)
    state_idx = SUBMISSION_COLUMNS.index(:state)
    data_idx  = SUBMISSION_COLUMNS.index(:emma_data)
    records.map! { |record|
      # Skip evaluation of the first (schema) row.
      unless record.first == 'id'
        next if submission_incomplete?(record[state_idx])
        next if submission_bogus?(record[data_idx])
      end
      record.values_at(*indices)
    }.compact!
    records
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
  BOGUS_TITLE_PREFIXES = %w[RWL IA_BULK].freeze

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
    data  = json_parse(emma_data, log: false) || {}
    title = data[:dc_title].to_s
    note  = data[:rem_comments].to_s
    title.blank? ||
      BOGUS_TITLE_PREFIXES.any? { title.start_with?(_1) } ||
      BOGUS_NOTE_WORDS.any? { note.include?(_1) }
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
