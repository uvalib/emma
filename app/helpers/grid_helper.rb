# app/helpers/grid_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module GridHelper

  include HtmlHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Options consumed by internal methods which should not be passed on along to
  # the methods which generate HTML elements.
  #
  # @type [Array<Symbol>]
  #
  # @see #grid_cell_classes
  #
  GRID_OPTS = %i[row col row_max col_max].freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a table of values.
  #
  # @param [Hash] pairs               Key-value pairs to display.
  # @param [Hash] opt                 Passed to outer #html_div except for:
  #                                     #GRID_OPTS and
  #
  # @option opt [Boolean] :wrap       If *true* then key/value pairs are joined
  #                                     within a wrapper element.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def grid_table(pairs, **opt)
    opt[:row]     ||= 0
    opt[:col]     ||= 0
    opt[:row_max] ||= pairs.size
    opt[:col_max] ||= 1
    wrap     = opt.delete(:wrap)
    html_opt = remainder_hash!(opt, *GRID_OPTS)
    html_div(html_opt) do
      pairs.map do |key, value|
        opt[:col] = 0  if opt[:col] == opt[:col_max]
        opt[:row] += 1 if opt[:col].zero?
        opt[:col] += 1
        r_opt = { class: grid_cell_classes(**opt) }
        k_opt = prepend_css(r_opt, 'key')
        v_opt = prepend_css(r_opt, 'value')
        if wrap
          prepend_css!(r_opt, 'entry')
          html_div(r_opt) do
            key = html_div(k_opt) { ERB::Util.h(key.to_s) << ':' }
            key << HTML_SPACE << html_div(value, v_opt)
          end
        else
          html_div(key, k_opt) << html_div(value, v_opt)
        end
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Array<#to_s,Array>] classes
  # @param [Hash]               opt       Internal options:
  #
  # @option opt [String]  :class
  # @option opt [Integer] :row        Grid row (wide screen).
  # @option opt [Integer] :col        Grid column (wide screen).
  # @option opt [Integer] :row_max    Bottom grid row (wide screen).
  # @option opt [Integer] :col_max    Rightmost grid column (wide screen).
  # @option opt [Boolean] :sr_only    If *true*, include 'sr-only' CSS class.
  #
  # @return [Array<String>]
  #
  def grid_cell_classes(*classes, **opt)
    row = positive(opt[:row])
    col = positive(opt[:col])
    classes += Array.wrap(opt[:class])
    classes << "row-#{row}" if row
    classes << "col-#{col}" if col
    classes << 'row-first'  if row == 1
    classes << 'col-first'  if col == 1
    classes << 'row-last'   if row == opt[:row_max].to_i
    classes << 'col-last'   if col == opt[:col_max].to_i
    classes << 'sr-only'    if opt[:sr_only]
    css_class_array(*classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #append_grid_cell_classes!
  #
  # @return [Hash]                        A new hash.
  #
  # @note Currently unused.
  #
  def append_grid_cell_classes(html_opt, *classes, **opt)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.deep_dup || {}
    append_grid_cell_classes!(html_opt, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def append_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    append_css!(html_opt, *classes)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       To #prepend_grid_cell_classes!.
  #
  # @return [Hash]                        A new hash.
  #
  # @note Currently unused.
  #
  def prepend_grid_cell_classes(html_opt, *classes, **opt)
    Log.debug { "#{__method__}: nil html_opt from #{caller}" } if html_opt.nil?
    html_opt = html_opt&.deep_dup || {}
    prepend_grid_cell_classes!(html_opt, *classes, **opt)
  end

  # Add CSS classes which indicate the position of the control within the grid.
  #
  # @param [Hash]               html_opt  The target options hash.
  # @param [Array<#to_s,Array>] classes   Additional CSS classes.
  # @param [Hash]               opt       Passed to #grid_cell_classes.
  #
  # @return [Hash]                        The modified *html_opt* hash.
  #
  def prepend_grid_cell_classes!(html_opt, *classes, **opt)
    classes = grid_cell_classes(*classes, **opt)
    prepend_css!(html_opt, *classes)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def self.included(base)
    __included(base, self)
    base.send(:extend,  self)
  end

end

__loading_end(__FILE__)
