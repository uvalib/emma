# app/decorators/base_decorator/table.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods supporting tabular display of Model instances.
#
module BaseDecorator::Table

  include BaseDecorator::List

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Make the heading row stick to the top of the table when scrolling.
  #
  # @type [Boolean]
  #
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class .sticky-head"
  #
  STICKY_HEAD = true

  # Give the heading row a background.
  #
  # @type [Boolean]
  #
  # @see file:stylesheets/layouts/controls/_tables.scss "CSS class .dark-head"
  #
  DARK_HEAD = true

  # Options used by some or all of the methods involved in rendering items in
  # a tabular form.
  #
  # @type [Array<Symbol>]
  #
  MODEL_TABLE_OPTIONS = [
    MODEL_TABLE_FIELD_OPT = %i[columns],
    MODEL_TABLE_HEAD_OPT  = %i[sticky dark],
    MODEL_TABLE_ENTRY_OPT = %i[inner_tag outer_tag],
    MODEL_TABLE_ROW_OPT   = %i[row col],
    MODEL_TABLE_TABLE_OPT = %i[model thead tbody tfoot],
  ].flatten.freeze

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  public

  # Render the object for use within a table of items.
  #
  # @param [Integer]                                   row
  # @param [Integer]                                   col
  # @param [Symbol, Integer, nil]                      outer_tag
  # @param [Symbol, Integer, nil]                      inner_tag
  # @param [String, Symbol, Array<String,Symbol>, nil] columns
  # @param [String, Regexp, Array<String,Regexp>, nil] filter
  # @param [Hash]                                      opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [Array<ActiveSupport::SafeBuffer>]  If nil :outer_tag.
  # @return [Array<String>]                     If nil :inner_tag, :outer_tag.
  #
  def table_entry(
    row:        1,
    col:        1,
    outer_tag:  :tr,
    inner_tag:  :td,
    columns:    nil,
    filter:     nil,
    **opt
  )
    opt.except!(*MODEL_TABLE_OPTIONS)
    pairs  = table_columns(columns: columns, filter: filter)
    fields =
      if inner_tag
        first_col = col
        last_col  = pairs.size + col - 1
        pairs.map do |field, value|
          row_opt = model_rc_options(field, row, col, opt)
          append_css!(row_opt, 'col-first') if col == first_col
          append_css!(row_opt, 'col-last')  if col == last_col
          col += 1
          html_tag(inner_tag, value, row_opt)
        end
      else
        pairs.values.compact.map { |value| ERB::Util.h(value) }
      end
    outer_tag ? html_tag(outer_tag, fields) : fields
  end

  # table_columns
  #
  # @param [Hash] opt                 Passed to #model_field_values
  #
  # @return [Hash]
  #
  def table_columns(**opt)
    model_field_values(**opt)
  end

  # ===========================================================================
  # :section: Item list (index page) support
  # ===========================================================================

  protected

  # Specified field selections from the given model instance.
  #
  # @param [Model, Hash, nil]                                         item
  # @param [String, Symbol, Array<String,Symbol>, nil]                columns
  # @param [String, Symbol, Array<String,Symbol>, nil]                default
  # @param [String, Symbol, Regexp, Array<String,Symbol,Regexp>, nil] filter
  #
  # @return [Hash{Symbol=>Any}]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def model_field_values(item = nil, columns: nil, default: nil, filter: nil, **)
    item ||= (object if present?)
    # noinspection RailsParamDefResolve
    pairs  = item&.try(:attributes) || item&.try(:stringify_keys)
    return {} if pairs.blank?
    columns = Array.wrap(columns || default).compact_blank.map(&:to_s)
    pairs.slice!(*columns) unless columns.blank? || (columns == %w(all))
    Array.wrap(filter).each do |pattern|
      case pattern
        when Regexp then pairs.reject! { |f, _| f.match?(pattern) }
        when Symbol then pairs.reject! { |f, _| f.casecmp?(pattern.to_s) }
        else             pairs.reject! { |f, _| f.downcase.include?(pattern) }
      end
    end
    pairs.transform_keys!(&:to_sym)
  end

  # Setup row/column HTML options.
  #
  # @param [Symbol, String] field
  # @param [Integer, nil]   row
  # @param [Integer, nil]   col
  # @param [Hash, nil]      opt
  #
  # @return [Hash]
  #
  #--
  # noinspection RubyMismatchedParameterType
  #++
  def model_rc_options(field, row = nil, col = nil, opt = nil)
    field = html_id(field)
    prepend_css(opt, field).tap do |html_opt|
      append_css!(html_opt, "row-#{row}") if row
      append_css!(html_opt, "col-#{col}") if col
      html_opt[:id] ||= [field, row, col].compact.join('-')
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
  end

end

__loading_end(__FILE__)
