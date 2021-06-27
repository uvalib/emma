# app/controllers/concerns/data_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Controller support methods for database access.
#
module DataConcern

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'DataConcern')
  end

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
  # @return [Hash]
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
  # @param [Array, *] value
  #
  # @return [Array<String>, nil]
  #
  def array_param(value)
    value = value.split(',')                        if value.is_a?(String)
    value.map { |s| s.to_s.strip.presence }.compact if value.is_a?(Array)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    names = Array.wrap(opt.delete(:tables) || names).presence || table_names
    names.map { |name| [name, table_records(name, *cols, **opt)] }.to_h
  end

  # Generate results for the indicated table.
  #
  # @param [String, Symbol, nil] name   Default: `params[:id]`
  # @param [Hash]                opt    Passed to DataHelper#table_records.
  #
  # @return [(String,Array)]
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
  # @param [String, Symbol, nil] name   Default: #SUBMISSION_TABLE.
  # @param [Hash]                opt    Passed to DataHelper#table_records.
  #
  # @return [(String,Array)]
  #
  def get_submission_records(name = nil, **opt)
    name ||= SUBMISSION_TABLE
    opt    = data_params.merge(**opt)

    # If columns have been specified, they are applied after the records have
    # been acquired and filtered based on the expected set of columns.
    columns = Array.wrap(opt.delete(:columns)).presence&.dup

    submission_records(**opt).tap do |_name, records|
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

  private

  BOGUS_TITLE_PREFIXES = %w(RWL IA_BULK)

  # Generate results for submission pseudo records.
  #
  # @param [Hash] opt                 Passed to #get_table_records.
  #
  # @return [(String,Array)]
  #
  def submission_records(**opt)
    get_table_records(SUBMISSION_TABLE, **opt)
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

  private

  def submission_result_columns(columns = nil)
    columns = Array.wrap(columns).presence&.map(:to_sym) || SUBMISSION_COLUMNS
    columns - %i[state]
  end

  def submission_result_indices(columns = nil)
    columns = submission_result_columns(columns)
    SUBMISSION_COLUMNS.map.with_index { |col, idx|
      idx if columns.include?(col)
    }.compact
  end

  def submission_incomplete?(state)
    state.present? && (state != 'completed')
  end

  def submission_bogus?(emma_data)
    (emma_data = json_parse(emma_data)).blank? || (emma_data == '{}') ||
      (title = emma_data[:dc_title].to_s).blank? ||
      %w(RWL IA_BULK).any? { |prefix| title.start_with?(prefix) }
  end

end

__loading_end(__FILE__)
